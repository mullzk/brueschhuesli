# frozen_string_literal: true

class CalendarMonth
  def self.for(day_in_month)
    first_of_month = day_in_month.beginning_of_month
    last_of_month = day_in_month.end_of_month
    reservations = Reservation.overlapping(first_of_month.beginning_of_day..last_of_month.end_of_day)
                              .includes(:user)
    new(first_of_month, reservations)
  end

  attr_reader :first_of_month

  def initialize(first_of_month, reservations)
    @first_of_month = first_of_month
    @reservations = reservations
  end

  def name
    I18n.l(first_of_month, format: :month_year)
  end

  # The grid runs from the Monday before the 1st to the Sunday after the last
  # day, so neighbouring-month days fill the corners (shown dimmed).
  def weeks
    grid_dates.each_slice(7).map do |week_dates|
      CalendarWeek.new(week_dates.map { |date| day_for(date) })
    end
  end

  private

  def grid_dates
    (first_of_month.beginning_of_week..first_of_month.end_of_month.end_of_week).to_a
  end

  def day_for(date)
    CalendarDay.new(date: date, reservations: reservations_on(date), in_month: in_month?(date))
  end

  def in_month?(date)
    date.between?(first_of_month, first_of_month.end_of_month)
  end

  def reservations_on(date)
    @reservations.select { |reservation| reservation.on_day?(date) }
                 .sort_by { |reservation| reservation.begin_on_day(date) }
  end
end
