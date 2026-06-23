# frozen_string_literal: true

# Spec-Tests (auskommentiert) — Vorhaben 3, Schritte 3–5 (System-Smokes).
# Schmale End-to-End-Belege für die neue Navigation (§5) und das
# Tagesdetail-/Formular-Overlay (§6/§7). Bis zur Aktivierung inert.
#
# Hinweis: `sign_in_as` (application_system_test_case) wartet heute auf
# `table.calendar`; mit dem neuen Grid (Schritt 2) wird dieser Warte-Selektor
# auf den neuen Kalender-Container angepasst.
#
# require "application_system_test_case"
#
# class ReservationsOverhaulTest < ApplicationSystemTestCase
#   # --- Schritt 3: Navigation / Infinite-Scroll ------------------------------
#
#   test "scrolling to the bottom appends the following month" do
#     travel_to Time.zone.local(2026, 6, 1, 10) do
#       sign_in_as
#       assert_text "Juni 2026"
#       assert_text "August 2026"
#       assert_no_text "September 2026"
#
#       page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
#
#       assert_text "September 2026"
#     end
#   end
#
#   test "the earlier button prepends the previous month" do
#     travel_to Time.zone.local(2026, 6, 1, 10) do
#       sign_in_as
#       assert_no_text "Mai 2026"
#
#       click_button "‹ Früher"
#
#       assert_text "Mai 2026"
#     end
#   end
#
#   test "the today button appears only after browsing into the past" do
#     travel_to Time.zone.local(2026, 6, 1, 10) do
#       sign_in_as
#       assert_no_button "Heute" # Gegenwart ist sichtbar
#
#       click_button "‹ Früher"
#       page.execute_script("window.scrollTo(0, 0)") # nach oben in die Vergangenheit
#
#       assert_button "Heute"
#     end
#   end
#
#   # --- Schritt 4/5: Tagesdetail- und Formular-Overlay -----------------------
#
#   test "clicking a day opens the detail overlay" do
#     travel_to Time.zone.local(2026, 6, 1, 10) do
#       user = sign_in_as
#       create(:reservation, user: user,
#              start: at("2026-06-10 14:00"), finish: at("2026-06-10 18:00"))
#
#       find("[data-date='2026-06-10']").click
#
#       assert_selector "dialog[open], .overlay.is-open"
#       assert_text "10."
#     end
#   end
#
#   test "reserving a free gap saves and closes the overlay" do
#     travel_to Time.zone.local(2026, 6, 1, 10) do
#       user = sign_in_as
#       create(:reservation, user: user,
#              start: at("2026-06-10 10:00"), finish: at("2026-06-10 14:00"))
#
#       find("[data-date='2026-06-10']").click
#       within "dialog[open], .overlay.is-open" do
#         click_link "reservieren", match: :first
#         click_button "Speichern"
#       end
#
#       assert_text "Reservation wurde gespeichert"
#       assert_no_selector "dialog[open], .overlay.is-open"
#     end
#   end
# end
