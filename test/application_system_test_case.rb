# frozen_string_literal: true

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  SCREEN_SIZES = { mobile: [ 390, 844 ], desktop: [ 1400, 1400 ] }.freeze

  # The browser session is reused across tests, so a mobile resize would leak
  # into later tests. Reset to desktop before each; mobile tests opt in.
  setup { resize_to(:desktop) }

  def resize_to(size)
    width, height = SCREEN_SIZES.fetch(size)
    page.driver.browser.manage.window.resize_to(width, height)
  end

  def sign_in_as(name: "Resident", email: "resident@example.com", password: "secret-password")
    user = User.create!(name: name, email: email, password: password)
    visit new_session_path
    fill_in "name", with: name
    fill_in "password", with: password
    click_button "Login"

    assert_selector "table.calendar" # wait for the post-login redirect to land
    user
  end
end
