require "test_helper"

class ReservationControllerTest < ActionDispatch::IntegrationTest
  # Valid reservation attributes for the nested :reservation params.
  def valid_params(user, overrides = {})
    {
      user_id: user.id,
      start: DateTime.new(2019, 3, 1, 14),
      finish: DateTime.new(2019, 3, 1, 18),
      type_of_reservation: Reservation::KURZAUFENTHALT,
      is_exclusive: true,
      comment: ""
    }.merge(overrides)
  end

  # --- authorization ---------------------------------------------------------

  test "index redirects to login when not authenticated" do
    get "/"
    assert_redirected_to controller: :login, action: :login
  end

  test "index renders when authenticated" do
    login_as_user
    get "/"
    assert_response :success
  end

  # --- new -------------------------------------------------------------------

  test "new renders a prefilled reservation" do
    login_as_user
    get new_reservation_path
    assert_response :success
  end

  test "new accepts a date param" do
    login_as_user
    get new_reservation_path(date: "2019-02-01")
    assert_response :success
  end

  # Verifies the Date.current/Time.current injection: with time frozen, new
  # prefills the form with the current date (year select shows the frozen year).
  test "new defaults to the current date" do
    travel_to Time.zone.local(2021, 7, 15, 10) do
      login_as_user
      get new_reservation_path
      assert_response :success
      assert_select "select#reservation_start_1i option[selected='selected']", text: "2021"
    end
  end

  # --- create ----------------------------------------------------------------

  test "create with valid params saves and redirects" do
    user = login_as_user
    assert_difference -> { Reservation.count }, 1 do
      post reservations_path, params: { reservation: valid_params(user) }
    end
    assert_equal "Reservation wurde gespeichert", flash[:notice]
    assert_response :redirect
  end

  # An invalid create re-renders the new form with 422 Unprocessable Entity so
  # Turbo replaces the page and shows the error (Turbo ignores 200/204).
  test "create with invalid params does not save" do
    user = login_as_user
    assert_no_difference -> { Reservation.count } do
      post reservations_path, params: {
        reservation: valid_params(user, finish: DateTime.new(2019, 3, 1, 10))
      }
    end
    assert_response :unprocessable_entity
    assert_equal "Reservation konnte nicht gespeichert werden", flash[:notice]
  end

  # --- edit / update ---------------------------------------------------------

  test "edit renders" do
    user = login_as_user
    reservation = Reservation.create!(valid_params(user))
    get edit_reservation_path(reservation)
    assert_response :success
  end

  test "edit preselects the classified type for a long stay stored as short" do
    user = login_as_user
    reservation = Reservation.create!(valid_params(user,
      start: DateTime.new(2019, 3, 1, 12), finish: DateTime.new(2019, 3, 4, 12)))
    get edit_reservation_path(reservation)
    assert_select "select#reservation_type_of_reservation option[selected='selected']",
      text: Reservation::FERIENAUFENTHALT
  end

  test "update with valid params saves and redirects" do
    user = login_as_user
    reservation = Reservation.create!(valid_params(user))
    patch reservation_path(reservation), params: {
      reservation: { finish: DateTime.new(2019, 3, 1, 20) }
    }
    assert_equal "Änderungen gespeichert.", flash[:notice]
    assert_response :redirect
    assert_equal DateTime.new(2019, 3, 1, 20), reservation.reload.finish
  end

  test "update with invalid params re-renders edit" do
    user = login_as_user
    reservation = Reservation.create!(valid_params(user))
    patch reservation_path(reservation), params: {
      reservation: { finish: DateTime.new(2019, 3, 1, 10) }
    }
    assert_response :unprocessable_entity
    assert_equal "Änderungen konnten nicht gespeichert werden.", flash[:notice]
  end

  # --- destroy ---------------------------------------------------------------

  test "destroy deletes and redirects" do
    user = login_as_user
    reservation = Reservation.create!(valid_params(user))
    assert_difference -> { Reservation.count }, -1 do
      delete reservation_path(reservation)
    end
    assert_redirected_to action: "index"
    assert_equal "Reservierung gelöscht", flash[:notice]
  end

  # --- month / on_day --------------------------------------------------------

  test "month renders the calendar partial" do
    login_as_user
    get "/reservations/month/2019-02-01"
    assert_response :success
  end

  test "on_day lists reservations for a date" do
    user = login_as_user
    Reservation.create!(valid_params(user))
    get "/reservations/on_day/2019-03-01"
    assert_response :success
  end
end
