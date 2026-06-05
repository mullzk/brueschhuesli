require "test_helper"

class DateLocalizationTest < ActiveSupport::TestCase
  test "month_year renders the German month and year" do
    assert_equal "März 2010", I18n.l(Date.new(2010, 3, 15), format: :month_year)
  end

  test "long renders weekday, day, month and year in German" do
    assert_equal "Montag, 05. Januar 2009", I18n.l(Date.new(2009, 1, 5), format: :long)
  end
end
