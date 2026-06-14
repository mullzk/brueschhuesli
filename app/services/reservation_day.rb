# frozen_string_literal: true

class ReservationDay
  def initialize(start:, finish:, day:)
    @start = start
    @finish = finish
    @day = day
  end

  def overlaps?
    @start <= @day.end_of_day && @finish > @day.beginning_of_day
  end

  def complete?
    @start <= @day.beginning_of_day && @finish > @day.end_of_day
  end

  def begins_at
    [ @start, @day.beginning_of_day ].max
  end

  def ends_at
    [ @finish, @day.end_of_day ].min
  end

  def hours
    return 24 if complete?

    ((ends_at - begins_at) / 1.hour.to_i).round
  end
end
