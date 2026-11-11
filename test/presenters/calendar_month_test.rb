# frozen_string_literal: true

require "test_helper"

class CalendarMonthTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test "lays out a Monday-first grid with neighbouring-month days in the corners" do
    month = CalendarMonth.new(Date.new(2019, 3, 1), [])

    assert_equal "März 2019", month.name
    assert_equal Date.new(2019, 3, 1), month.first_of_month
    assert(month.weeks.all? { |week| week.days.size == 7 })

    first_week = month.weeks.first

    assert first_week.days.first(4).none?(&:in_month?) # Fr 1. März steht in Spalte 5
    assert_equal Date.new(2019, 3, 1), first_week.days[4].date
    assert_predicate first_week.days[4], :in_month?
    assert_equal 31, month.weeks.flat_map(&:days).select(&:in_month?).size
  end

  test "classifies each day as free, occupied or today" do
    travel_to Time.zone.local(2019, 3, 15) do
      create(:reservation, user: @user, start: at("2019-03-10 14:00"), finish: at("2019-03-10 18:00"))
      days = days_by_date(CalendarMonth.for(Date.new(2019, 3, 1)))

      assert_predicate days[Date.new(2019, 3, 10)], :occupied?
      assert_predicate days[Date.new(2019, 3, 11)], :free?
      assert_predicate days[Date.new(2019, 3, 15)], :today?
      assert_not_predicate days[Date.new(2019, 3, 10)], :today?
    end
  end

  test "shows a multi-day reservation on every day it spans" do
    reservation = create(:reservation, user: @user, start: at("2019-03-10 14:00"), finish: at("2019-03-12 18:00"))
    days = days_by_date(CalendarMonth.for(Date.new(2019, 3, 1)))

    assert_includes days[Date.new(2019, 3, 10)].reservations, reservation
    assert_includes days[Date.new(2019, 3, 11)].reservations, reservation
    assert_includes days[Date.new(2019, 3, 12)].reservations, reservation
    assert_not_includes days[Date.new(2019, 3, 9)].reservations, reservation
    assert_not_includes days[Date.new(2019, 3, 13)].reservations, reservation
  end

  private

  def days_by_date(month)
    month.weeks.flat_map(&:days).index_by(&:date)
  end
end
