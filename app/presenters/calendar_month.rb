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

  def weeks
    cells.in_groups_of(7)
  end

  private

  # Blank cells before the 1st and after the last day keep each day under its
  # weekday column.
  def cells
    last_of_month = first_of_month.end_of_month
    leading = (first_of_month - first_of_month.beginning_of_week).to_i
    trailing = (last_of_month.end_of_week - last_of_month).to_i

    ([ nil ] * leading) +
      (first_of_month..last_of_month).map { |date| CalendarDay.new(date, reservations_on(date)) } +
      ([ nil ] * trailing)
  end

  def reservations_on(date)
    @reservations.select { |reservation| reservation.on_day?(date) }
                 .sort_by { |reservation| reservation.begin_on_day(date) }
  end
end
