# frozen_string_literal: true

require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  test "mobile navigation opens via the hamburger toggle" do
    resize_to(:mobile)
    sign_in_as

    assert_selector ".site-nav__toggle"
    assert_no_link "Reservationen"

    find(".site-nav__toggle").click

    assert_link "Reservationen"
    assert_link "Abmelden"
  end
end
