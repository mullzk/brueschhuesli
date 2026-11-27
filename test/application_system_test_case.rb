# frozen_string_literal: true

require "test_helper"

# Capybara 3.40 resets Chrome storage with origin "*", which Chrome 158+
# rejects (teamcapybara/capybara#2865). Clear cookies globally and the
# remaining storage for the app server's origin instead. Drop this once a
# Capybara release ships the fix.
module ClearChromeStorageWithoutWildcardOrigin
  private

  def execute_cdp(cmd, params = {})
    return super unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

    types = params[:storageTypes].to_s.split(",")
    super("Network.clearBrowserCookies") if types.delete("cookies")

    origin = Capybara.current_session.server&.base_url
    super(cmd, params.merge(origin: origin, storageTypes: types.join(","))) if origin && types.any?
  end
end
Capybara::Selenium::Driver::ChromeDriver.prepend(ClearChromeStorageWithoutWildcardOrigin)

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  SCREEN_SIZES = { mobile: [ 390, 844 ], tablet: [ 800, 1000 ], desktop: [ 1400, 1400 ] }.freeze

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

    assert_selector ".calendar" # wait for the post-login redirect to land
    user
  end
end
