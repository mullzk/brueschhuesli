# frozen_string_literal: true

require "test_helper"

class ReservationsOverhaulControllerTest < ActionDispatch::IntegrationTest
  # --- Schritt 4: Tagesdetail als Overlay-Frame -------------------------------

  test "on_day renders inside a turbo-frame so it can open as an overlay" do
    login_as_user
    get "/reservations/on_day/2026-07-01", headers: { "Turbo-Frame" => "modal" }

    assert_response :success
    assert_select "turbo-frame#modal"
  end

  test "on_day offers a reserve action for the free gap of a partly booked day" do
    user = login_as_user
    create(:reservation, user: user,
                         start: at("2026-07-01 10:00"), finish: at("2026-07-01 14:00"))
    get "/reservations/on_day/2026-07-01"

    # the free gap links to the form for that day
    assert_select "a[href*='/reservations/new'][href*='2026-07-01']"
  end

  # --- Schritt 5: natives datetime-local statt date_select/time_select (komm.) -
  #
  #   test "new renders native datetime-local fields for start and finish" do
  #     login_as_user
  #     get new_reservation_path
  #
  #     assert_select "input[type=datetime-local][name='reservation[start]']"
  #     assert_select "input[type=datetime-local][name='reservation[finish]']"
  #     assert_select "select#reservation_start_1i", false
  #   end
  #
  #   test "create accepts an ISO string from a datetime-local field" do
  #     user = login_as_user
  #     assert_difference -> { Reservation.count }, 1 do
  #       post reservations_path, params: { reservation: {
  #         user_id: user.id,
  #         start: "2026-07-01T14:00",
  #         finish: "2026-07-01T18:00",
  #         type_of_reservation: Reservation::KURZAUFENTHALT,
  #         is_exclusive: true,
  #         comment: ""
  #       } }
  #     end
  #     assert_response :redirect
  #     assert_equal at("2026-07-01 14:00"), Reservation.last.start
  #   end
  #
  # --- Schritt 6: Delete-Redirect (Roadmap #4) (kommentiert) ------------------
  #
  #   test "destroy redirects to the calendar, never to the deleted record" do
  #     user = login_as_user
  #     reservation = create(:reservation, user: user)
  #     delete reservation_path(reservation)
  #
  #     assert_response :redirect
  #     assert_no_match %r{/reservations/#{reservation.id}\b}, @response.redirect_url
  #   end
end
