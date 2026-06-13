module ApplicationHelper
  def time_components_of(numeric)
    (reminder, secs) = numeric.divmod(60)
    (reminder, mins) = reminder.divmod(60)
    (days, hours) = reminder.divmod(24)

    { seconds: secs, minutes: mins, hours: hours, days: days }
  end

  def time_component_string_of(numeric)
    comps = time_components_of(numeric)
    days = comps[:days]
    hours = comps[:hours]

    if days > 0
      "%id %.2ih" % [ days, hours ]
    else
      "%.ih" % [ hours ]
    end
  end
end
