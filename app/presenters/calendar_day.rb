# frozen_string_literal: true

class CalendarDay
  attr_reader :date, :reservations

  def initialize(date:, reservations:, in_month: true)
    @date = date
    @reservations = reservations
    @in_month = in_month
  end

  def in_month?
    @in_month
  end

  def free?
    reservations.empty?
  end

  def occupied?
    reservations.any?
  end

  def today?
    date == Date.current
  end
end
