require "test_helper"

class CalendarMonthTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test "lays out the days under their weekday with leading and trailing blanks" do
    month = CalendarMonth.new(Date.new(2019, 3, 1), [])

    assert_equal "März 2019", month.name
    assert_equal Date.new(2019, 3, 1), month.first_of_month
    assert_equal 5, month.weeks.size
    assert(month.weeks.all? { |week| week.size == 7 })

    first_week = month.weeks.first

    assert_equal [ nil, nil, nil, nil ], first_week.first(4)
    assert_equal 1, first_week[4].date.day
    assert_equal 31, month.weeks.flatten.compact.size
  end

  test "classifies each day as free, occupied or today" do
    travel_to Time.zone.local(2019, 3, 15) do
      create(:reservation, user: @user, start: at("2019-03-10 14:00"), finish: at("2019-03-10 18:00"))
      days = days_by_date(CalendarMonth.for(Date.new(2019, 3, 1)))

      assert_predicate days[Date.new(2019, 3, 10)], :occupied?
      assert_predicate days[Date.new(2019, 3, 11)], :free?
      assert_predicate days[Date.new(2019, 3, 15)], :today?
      refute_predicate days[Date.new(2019, 3, 10)], :today?
    end
  end

  test "shows a multi-day reservation on every day it spans" do
    reservation = create(:reservation, user: @user, start: at("2019-03-10 14:00"), finish: at("2019-03-12 18:00"))
    days = days_by_date(CalendarMonth.for(Date.new(2019, 3, 1)))

    assert_includes days[Date.new(2019, 3, 10)].reservations, reservation
    assert_includes days[Date.new(2019, 3, 11)].reservations, reservation
    assert_includes days[Date.new(2019, 3, 12)].reservations, reservation
    refute_includes days[Date.new(2019, 3, 9)].reservations, reservation
    refute_includes days[Date.new(2019, 3, 13)].reservations, reservation
  end

  private

  def days_by_date(month)
    month.weeks.flatten.compact.index_by(&:date)
  end
end
