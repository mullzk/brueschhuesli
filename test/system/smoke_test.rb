require "application_system_test_case"

# Minimal smoke test that proves the system-test pipeline (headless Chrome +
# Capybara + booted Puma) actually works. The login page is the only view
# reachable without authentication. Real flow coverage follows in Phase 6.
class SmokeTest < ApplicationSystemTestCase
  test "login page renders" do
    visit new_session_path

    assert_text "Bitte einloggen"
  end
end
