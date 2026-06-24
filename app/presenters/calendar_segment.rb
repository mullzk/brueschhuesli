# frozen_string_literal: true

# One reservation's slice within a single calendar week: which columns it spans
# (1 = Monday … 7 = Sunday), whether it continues beyond this week's edges, and
# the lane it was packed into to avoid overlapping other segments.
class CalendarSegment
  attr_reader :reservation, :start_col, :end_col
  attr_accessor :lane

  def initialize(reservation:, start_col:, end_col:, continues_left:, continues_right:)
    @reservation = reservation
    @start_col = start_col
    @end_col = end_col
    @continues_left = continues_left
    @continues_right = continues_right
  end

  def continues_left?
    @continues_left
  end

  def continues_right?
    @continues_right
  end

  def exclusive?
    reservation.is_exclusive
  end

  # Occupies a single column — as narrow as a one-day bar, so it gets the
  # taller, two-line treatment regardless of whether it continues elsewhere.
  def single_column?
    start_col == end_col
  end

  # A genuine within-one-day reservation: only these show a time, since a
  # month/week-boundary slice would report a misleading partial time.
  def single_day?
    single_column? && !continues_left? && !continues_right?
  end
end
