require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  SCREEN_SIZES = { mobile: [ 390, 844 ], desktop: [ 1400, 1400 ] }.freeze

  def resize_to(size)
    width, height = SCREEN_SIZES.fetch(size)
    page.driver.browser.manage.window.resize_to(width, height)
  end
end
