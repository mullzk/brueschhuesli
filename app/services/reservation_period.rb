# frozen_string_literal: true

class ReservationPeriod
  def initialize(start:, finish:)
    @start = start
    @finish = finish
  end

  def duration
    @finish - @start
  end

  def duration_in_days
    # Billed per calendar day touched. A reservation ending exactly at midnight
    # does not count the following day (it only touches that day's first instant).
    last_day = @finish == @finish.beginning_of_day ? @finish.to_date - 1 : @finish.to_date
    (last_day - @start.to_date).to_i + 1
  end

  def duration_rounded_to_hours
    floor_to_hour(@finish) - floor_to_hour(@start)
  end

  def duration_in_8_hour_blocks
    (duration_rounded_to_hours / 8.hours.to_i).ceil
  end

  def to_s
    finish_format = same_day? ? "%H:%M" : "%d.%m.%Y, %H:%M"
    "#{@start.strftime('%d.%m.%Y, %H:%M')} bis #{@finish.strftime(finish_format)}"
  end

  private

  def same_day?
    @start.to_date == @finish.to_date
  end

  def floor_to_hour(time)
    DateTime.new(time.year, time.month, time.day, time.hour, 0).in_time_zone
  end
end
