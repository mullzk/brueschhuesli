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

  test "the earlier link prepends the previous twelve months" do
    travel_to Time.zone.local(2026, 6, 1, 10) do
      sign_in_as

      assert_no_text "Mai 2026"

      click_link "‹ Früher"

      assert_text "Juni 2025"
      assert_text "Mai 2026"
      assert_no_text "Mai 2025"
    end
  end

  test "the earlier link keeps the viewport anchored on the current month" do
    travel_to Time.zone.local(2026, 6, 1, 10) do
      sign_in_as

      juni = find("h2", text: "Juni 2026")
      before = juni.native.rect.y - page.evaluate_script("window.scrollY")

      click_link "‹ Früher"

      assert_text "Juni 2025"

      after = juni.native.rect.y - page.evaluate_script("window.scrollY")

      assert_in_delta before, after, 5, "calendar jumped by #{(after - before).round}px"
    end
  end

  test "the today button appears only after browsing into the past" do
    travel_to Time.zone.local(2026, 6, 1, 10) do
      resize_to(:mobile)
      sign_in_as

      assert_no_button "Heute" # today is visible on load

      click_link "‹ Früher"

      assert_text "Juni 2025"
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

  # --- Schritt 7: Multi-Tag-Drag → Neue Reservation ---------------------------

  test "dragging across several days opens the new form for that range" do
    travel_to Time.zone.local(2026, 6, 1, 10) do
      sign_in_as

      from = find("[data-date='2026-06-10']")
      to   = find("[data-date='2026-06-13']")
      page.driver.browser.action.click_and_hold(from.native)
          .move_to(to.native).release.perform

      within ".overlay:not([hidden])" do
        assert_field "reservation[start]", with: /^2026-06-10/
        assert_field "reservation[finish]", with: /^2026-06-13|^2026-06-14/
      end
    end
  end

  test "a plain click is not treated as a drag" do
    travel_to Time.zone.local(2026, 6, 1, 10) do
      sign_in_as
      find("[data-date='2026-06-10']").click

      within ".overlay:not([hidden])" do
        assert_field "reservation[start]", with: /^2026-06-10/
        assert_field "reservation[finish]", with: /^2026-06-11/
      end
    end
  end

  test "dragging within a week across the month boundary opens the new form for that range" do
    travel_to Time.zone.local(2026, 6, 1, 10) do
      sign_in_as

      from = find(".calendar__cell--out[data-date='2026-06-30']")
      to   = find(".calendar__cell--free[data-date='2026-07-01']")
      page.driver.browser.action.click_and_hold(from.native)
          .move_to(to.native).release.perform

      within ".overlay:not([hidden])" do
        assert_field "reservation[start]", with: /^2026-06-30/
        assert_field "reservation[finish]", with: /^2026-07-01/
      end
    end
  end

  test "an external use shows as Extern in the calendar and names the user in the detail" do
    travel_to Time.zone.local(2026, 6, 1, 10) do
      tenant = create(:user, name: "Mieterin")
      create(:reservation, user: tenant, type_of_reservation: Reservation::EXTERNE_NUTZUNG,
                           start: Time.zone.local(2026, 6, 10, 10), finish: Time.zone.local(2026, 6, 11, 10),
                           comment: "Firmenanlass")
      sign_in_as

      within(".calendar__bar") { assert_text "Extern" }
      assert_no_selector ".calendar__bar", text: "Mieterin"

      find("[data-date='2026-06-10']").click

      within ".overlay:not([hidden])" do
        assert_text "Mieterin"
        assert_text "Firmenanlass"
      end
    end
  end
end
