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

  def single_day?
    start_col == end_col && !continues_left? && !continues_right?
  end
end
