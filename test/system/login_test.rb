require "application_system_test_case"

class LoginTest < ApplicationSystemTestCase
  # Regression test for the Turbo form bug introduced in #31: an invalid login
  # must show feedback. Previously the controller answered with 200, which
  # Turbo silently ignores, so nothing appeared on screen.
  test "invalid login shows an error message" do
    User.create!(name: "Resident", email: "resident@example.com", password: "correct-horse")

    visit login_login_path
    fill_in "name", with: "Resident"
    fill_in "password", with: "wrong"
    click_button "Login"

    assert_text "Ungültige Benutzer/Passwort Kombination"
  end

  test "valid login reaches the calendar" do
    User.create!(name: "Resident", email: "resident@example.com", password: "correct-horse")

    visit login_login_path
    fill_in "name", with: "Resident"
    fill_in "password", with: "correct-horse"
    click_button "Login"

    assert_no_text "Ungültige Benutzer/Passwort Kombination"
  end
end
