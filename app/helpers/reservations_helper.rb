module ReservationsHelper
  def tagged_form_for(name, *args, &block)
    options = args.last.is_a?(Hash) ? args.pop : {}
    options = options.merge(:builder => TaggedBuilder)
    args = (args << options)
    form_for(name, *args, &block)
  end
  
  def time_as_month_and_year(time)
    time.strftime("%Y-%m")
  end
  
  def day_in_month(date)
    if date == Date.today
      return "current-day"
    elsif date.month==@listed_month.month
      return "active-month"
    else
      return "inactive-month"
    end
  end
  
  def link_to_month(date)
    link_to (date).strftime_german("%B %Y"), :action => "index", :month => time_as_month_and_year(date)
  end
  
  def link_to_reservation(res)
    if res
      link_to_remote res.user.name, {:url => {:action => "show_detail", :id => res.id}}, 
                                    {:onclick => "document.getElementById('calendarDetailsBox').style.display='none';
                                                  document.getElementById('calendarNewReservationBox').style.display='none';
                                                  event.cancelBubble = true; 
                                                  if(event.stopPropagation) event.stopPropagation();", 
                                     :href => url_for({ :action => 'show_detail', 
                                                        :id => res.id })}
    end
  end
  
  def ajax_link_to_new_reservation(date)
    "onclick=\"" + link_to(:url => {:action => "new_reservation_in_ajax", :date => date}) + "\""
  end
  
  def help_div_with_class_and_link_to_reservation(reservation_class, reservation, day)
    excl = if reservation.is_exclusive then "exclusive" else "openhouse" end
    complete = if reservation.fills_complete_day?(day) then "complete" else "partial" end
    str = "<div class=\"#{reservation_class} #{excl} #{complete}\""
    str += "onclick=\"" +  remote_function(:url => {:action => "show_detail", :id => reservation.id}) + "\">"
    str += link_to_reservation reservation
    str += "<span class=\"timeslothint\"> #{reservation.hours_on_day(day)}h</span>" unless reservation.fills_complete_day?(day)
	  str += "</div>"
	  return str
  end
end
