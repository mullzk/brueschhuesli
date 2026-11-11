# frozen_string_literal: true

require "test_helper"

class ReservationPeriodTest < ActiveSupport::TestCase
  def period(start, finish)
    ReservationPeriod.new(start: at(start), finish: at(finish))
  end

  test "a same-day span omits the date on the finish" do
    assert_equal "01.02.2010, 09:00 bis 17:00", period("2010-02-01 09:00", "2010-02-01 17:00").to_s
  end

  test "a multi-day span keeps the date on both ends" do
    assert_equal "01.02.2010, 21:00 bis 02.02.2010, 10:00", period("2010-02-01 21:00", "2010-02-02 10:00").to_s
  end
end
