class CalendarDay
  attr_reader :date, :reservations

  def initialize(date, reservations)
    @date = date
    @reservations = reservations
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
