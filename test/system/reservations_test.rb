# frozen_string_literal: true

require "application_system_test_case"

class ReservationsTest < ApplicationSystemTestCase
  test "create a reservation from the calendar" do
    sign_in_as
    day = Date.current.beginning_of_month + 14
    find(".calendar__cell--free[data-enter-href-url-value$='new?date=#{day.iso8601}']").click

    click_button "Speichern"

    assert_text "Reservation wurde gespeichert"
    assert_text "Resident"
  end

  test "edit a reservation" do
    user = sign_in_as
    reservation = create(:reservation, user: user)

    visit edit_reservation_path(reservation)
    fill_in "reservation_comment", with: "Geänderter Kommentar"
    click_button "Speichern"

    assert_text "Änderungen gespeichert."
    assert_equal "Geänderter Kommentar", reservation.reload.comment
  end

  test "delete a reservation" do
    user = sign_in_as
    reservation = create(:reservation, user: user)

    visit edit_reservation_path(reservation)
    accept_confirm { click_button "Reservation Löschen" }

    assert_text "Reservierung gelöscht"
    assert_not Reservation.exists?(reservation.id)
  end

  test "an overlapping reservation is rejected" do
    user = sign_in_as
    create(:reservation, user: user,
                         start: DateTime.new(2026, 7, 1, 0), finish: DateTime.new(2026, 7, 2, 0))

    visit new_reservation_path(date: "2026-07-01")
    click_button "Speichern"

    assert_text "überlappt"
  end
end
