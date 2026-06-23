# frozen_string_literal: true

# Spec-Tests (auskommentiert) — Vorhaben 3, Schritte 4–6.
# Aktiviert mit dem Tagesdetail-Overlay (§6), dem modernisierten Formular mit
# nativen datetime-local-Feldern (§7) und dem Delete-Redirect (§8). Bis dahin
# inert. Ergänzt den bestehenden reservation_controller_test, der parallel an
# die neue Markup-Struktur angepasst wird.
#
# require "test_helper"
#
# class ReservationsOverhaulTest < ActionDispatch::IntegrationTest
#   # --- Schritt 5: native datetime-local statt date_select/time_select --------
#
#   test "new renders native datetime-local fields for start and finish" do
#     login_as_user
#     get new_reservation_path
#
#     assert_select "input[type=datetime-local][name='reservation[start]']"
#     assert_select "input[type=datetime-local][name='reservation[finish]']"
#     # die alten Multiparameter-Selects sind weg
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
#   # --- Schritt 4: Tagesdetail als Overlay-Frame -----------------------------
#
#   test "on_day renders inside a turbo-frame so it can open as an overlay" do
#     login_as_user
#     get "/reservations/on_day/2026-07-01"
#
#     assert_response :success
#     assert_select "turbo-frame#modal"
#   end
#
#   test "on_day offers a reserve action for the free gap of a partly booked day" do
#     user = login_as_user
#     create(:reservation, user: user,
#            start: at("2026-07-01 10:00"), finish: at("2026-07-01 14:00"))
#     get "/reservations/on_day/2026-07-01"
#
#     # die freie Lücke verlinkt aufs Formular für genau diesen Tag
#     assert_select "a[href*='/reservations/new'][href*='2026-07-01']"
#   end
#
#   # --- Schritt 6: Delete-Redirect (Roadmap #4) ------------------------------
#
#   test "destroy redirects to the calendar, never to the deleted record" do
#     user = login_as_user
#     reservation = create(:reservation, user: user)
#     delete reservation_path(reservation)
#
#     assert_response :redirect
#     assert_no_match %r{/reservations/#{reservation.id}\b}, @response.redirect_url
#   end
# end
