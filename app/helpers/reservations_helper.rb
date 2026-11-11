# frozen_string_literal: true

module ReservationsHelper
  # Time within a day, showing 00:00/24:00 for slots that run to the day's edge.
  def day_time(time, day)
    return "00:00" if time <= day.beginning_of_day
    return "24:00" if time >= day.end_of_day

    time.strftime("%H:%M")
  end

  # A reservation's span; collapses to times only when it stays within one day.
  def reservation_span(reservation)
    if reservation.start.to_date == reservation.finish.to_date
      "#{reservation.start.strftime('%H:%M')}–#{reservation.finish.strftime('%H:%M')}"
    else
      "#{reservation.start.strftime('%-d.%-m. %H:%M')} – #{reservation.finish.strftime('%-d.%-m. %H:%M')}"
    end
  end
end
