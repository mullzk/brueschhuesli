# frozen_string_literal: true

# A single week of the month grid: seven CalendarDay cells plus the spanning
# reservation bars (segments), lane-packed so overlapping reservations stack.
class CalendarWeek
  attr_reader :days

  def initialize(days)
    @days = days
  end

  def segments
    @segments ||= build_segments
  end

  private

  def in_month_days
    days.select(&:in_month?)
  end

  def week_reservations
    in_month_days.flat_map(&:reservations).uniq
  end

  def build_segments
    segments = week_reservations.map { |reservation| segment_for(reservation) }
    assign_lanes(segments)
    segments
  end

  def segment_for(reservation)
    covered = in_month_days.select { |day| reservation.on_day?(day.date) }.map(&:date)
    CalendarSegment.new(
      reservation: reservation,
      start_col: column_of(covered.first),
      end_col: column_of(covered.last),
      continues_left: reservation.on_day?(covered.first - 1),
      continues_right: reservation.on_day?(covered.last + 1)
    )
  end

  def column_of(date)
    (date - date.beginning_of_week).to_i + 1
  end

  # First-fit packing: segments drop into the first lane whose last segment has
  # already ended before this one starts. Within a column the earlier-starting
  # reservation takes the upper lane, so lanes read chronologically.
  def assign_lanes(segments)
    segments.sort_by! { |segment| [ segment.start_col, segment.reservation.start ] }
    lane_ends = []
    segments.each do |segment|
      lane = lane_ends.index { |end_col| end_col < segment.start_col } || lane_ends.size
      lane_ends[lane] = segment.end_col
      segment.lane = lane
    end
  end
end
