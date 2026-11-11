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

  test "a wrapping header pushes the page content down instead of covering it" do
    resize_to(:tablet)
    sign_in_as

    header = find(".site-header").native.rect
    earlier = find_link("‹ Früher").native.rect

    assert_operator header.height, :>, 70, "header did not wrap at this width"
    assert_operator earlier.y, :>=, header.y + header.height
  end
end
