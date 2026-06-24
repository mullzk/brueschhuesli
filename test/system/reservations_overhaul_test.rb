# frozen_string_literal: true

require "application_system_test_case"

class ReservationsOverhaulSystemTest < ApplicationSystemTestCase
  # --- Schritt 3: Navigation / Infinite-Scroll --------------------------------

  test "scrolling to the bottom appends the following month" do
    travel_to Time.zone.local(2026, 6, 1, 10) do
      sign_in_as

      assert_text "Juni 2026"
      assert_text "August 2026"
      assert_no_text "September 2026"

      page.execute_script("window.scrollTo(0, document.body.scrollHeight)")

      assert_text "September 2026"
    end
  end

  test "the earlier link prepends the previous month" do
    travel_to Time.zone.local(2026, 6, 1, 10) do
      sign_in_as

      assert_no_text "Mai 2026"

      click_link "‹ Früher"

      assert_text "Mai 2026"
    end
  end

  test "the today button appears only after browsing into the past" do
    travel_to Time.zone.local(2026, 6, 1, 10) do
      resize_to(:mobile)
      sign_in_as

      assert_no_button "Heute" # today is visible on load

      click_link "‹ Früher"

      assert_text "Mai 2026"
      click_link "‹ Früher"

      assert_text "April 2026"
      page.execute_script("window.scrollTo(0, 0)") # today now far below the fold

      assert_button "Heute"
    end
  end

  # --- Schritt 4: Tagesdetail-Overlay -----------------------------------------

  test "clicking an occupied day opens the detail overlay" do
    travel_to Time.zone.local(2026, 6, 1, 10) do
      resident = User.create!(name: "Toni Bernhard", email: "toni@example.com", password: "secret-password")
      create(:reservation, user: resident,
                           start: at("2026-06-10 14:00"), finish: at("2026-06-10 18:00"))
      sign_in_as

      find("[data-date='2026-06-10']").click

      assert_selector ".overlay__sheet", text: "Toni Bernhard"
    end
  end

  # --- Schritt 5: Formular-Overlay --------------------------------------------

  test "reserving a free gap saves and closes the overlay" do
    travel_to Time.zone.local(2026, 6, 1, 10) do
      resident = User.create!(name: "Toni Bernhard", email: "toni@example.com", password: "secret-password")
      create(:reservation, user: resident,
                           start: at("2026-06-10 10:00"), finish: at("2026-06-10 14:00"))
      sign_in_as

      find("[data-date='2026-06-10']").click
      within ".overlay:not([hidden])" do
        click_link "reservieren", match: :first
        click_button "Speichern"
      end

      assert_text "Reservation wurde gespeichert"
      assert_no_selector ".overlay:not([hidden])"
    end
  end
end
