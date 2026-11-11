# frozen_string_literal: true

# Orders a day's reservations together with the free gaps between them, so the
# day-detail overlay can offer "reservieren" on every open slot. Open (non-
# exclusive) reservations are merged for gap detection, so a gap is time the
# house is genuinely unbooked.
class DaySchedule
  Slot = Struct.new(:reservation, :from, :to, keyword_init: true) do
    def free?
      reservation.nil?
    end
  end

  def self.for(date, reservations)
    new(date, reservations)
  end

  def initialize(date, reservations)
    @date = date
    @reservations = reservations
  end

  def slots
    (reservation_slots + free_slots).sort_by(&:from)
  end

  private

  attr_reader :date, :reservations

  def reservation_slots
    reservations.map do |reservation|
      Slot.new(reservation: reservation, from: reservation.begin_on_day(date), to: reservation.end_on_day(date))
    end
  end

  def free_slots
    gaps.map { |from, to| Slot.new(reservation: nil, from: from, to: to) }
  end

  def gaps
    result = []
    cursor = date.beginning_of_day
    covered.each do |from, to|
      result << [ cursor, from ] if from > cursor
      cursor = [ cursor, to ].max
    end
    result << [ cursor, date.end_of_day ] if cursor < date.end_of_day
    result
  end

  def covered
    intervals = reservations
                .map { |reservation| [ reservation.begin_on_day(date), reservation.end_on_day(date) ] }
                .sort_by(&:first)
    intervals.each_with_object([]) do |(from, to), merged|
      if merged.any? && from <= merged.last[1]
        merged.last[1] = [ merged.last[1], to ].max
      else
        merged << [ from, to ]
      end
    end
  end
end
