# == Schema Information
#
# Table name: reservations
#
#  id                  :bigint(8)        not null, primary key
#  comment             :text
#  finish              :datetime
#  is_exclusive        :boolean
#  start               :datetime
#  type_of_reservation :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  user_id             :bigint(8)
#
# Indexes
#
#  index_reservations_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class Reservation < ApplicationRecord
  belongs_to :user
  validates_presence_of :start, :finish, :type_of_reservation
  validate :is_timeslot_exclusive?, :is_timeslot_positive?, :is_reservation_not_longer_than_a_week?

  KURZAUFENTHALT = "Kurzaufenthalt"
  FERIENAUFENTHALT = "Ferienaufenthalt"
  GROSSANLASS = "Grossanlass"
  EXTERNE_NUTZUNG = "Nutzung durch Dritte"
  
  def self.reservation_types
    @reservation_types ||= {}
    @reservation_types[:KURZAUFENTHALT] = KURZAUFENTHALT
    @reservation_types[:FERIENAUFENTHALT] = FERIENAUFENTHALT
    @reservation_types[:GROSSANLASS] = GROSSANLASS
    @reservation_types[:EXTERNE_NUTZUNG] = EXTERNE_NUTZUNG
    @reservation_types.sort {|a,b| a[1]<=>b[1]}
  end
  

  def duration
    finish-start
  end
  
  def duration_in_complete_days_evaluated_in_seconds
    fin = DateTime.new(finish.year, finish.month, finish.day, 24, 0).in_time_zone
    sta = DateTime.new(start.year, start.month, start.day, 0, 0).in_time_zone

    fin - sta
  end
  
  def duration_in_days
    self.duration_in_complete_days_evaluated_in_seconds/(24*60*60)
  end
  
  def duration_rounded_to_hours
    fin = DateTime.new(finish.year, finish.month, finish.day, finish.hour, 0).in_time_zone
    sta = DateTime.new(start.year, start.month, start.day, start.hour, 0).in_time_zone
    
    fin - sta
  end
  
  def duration_in_8_hour_blocks
    eight_hours = 8 * 60 * 60
    (duration_rounded_to_hours/eight_hours).ceil
  end
  
  def paid_blocks
    blocks = duration_in_8_hour_blocks
    if user.miteigentuemer? && !is_exclusive?
      if blocks <= 6
        0
      else
        blocks - 6
      end
    else
      blocks
    end
  end
  
  def billed_fee
    if type_of_reservation.eql?(Reservation::KURZAUFENTHALT) || type_of_reservation.eql?(Reservation::FERIENAUFENTHALT)
      paid_blocks * 15
    elsif type_of_reservation.eql?(Reservation::GROSSANLASS)
      200
    elsif type_of_reservation.eql?(Reservation::EXTERNE_NUTZUNG)
      duration_in_days * 100   #duration_in_days_returns_seconds !!!!
    end
  end
  
  
  def german_date
    self.date.short_german_std
  end
  
  def german_date=(str)
    self.date= Date.parse_german_string(str)
  end
  
  def type_of_reservation
    saved_reservation_type = self[:type_of_reservation]
    if saved_reservation_type.eql?(Reservation::KURZAUFENTHALT) && duration > 60*60*48 
      Reservation::FERIENAUFENTHALT
    elsif saved_reservation_type.eql?(Reservation::FERIENAUFENTHALT) && duration < 60*60*48 
      Reservation::KURZAUFENTHALT
    else
      saved_reservation_type
    end
  end
  
  
  def overlaps_with?(other)
    if other.start==self.start || other.finish==self.finish
      true
    elsif other.start==self.finish || self.start==other.finish
      false
    elsif self.start < other.start
      other.start < self.finish
    else other.start < self.start
      self.start < other.finish
    end
  end
  
  # Returns only reservations with beginning in a timeslot, e.g. Reservations that span multiple months are reported only in the first month. This makes calculating the tariffs much easier
  def self.find_reservations_beginning_in_timeslot(time_a, time_b)
    if time_a > time_b
      if time_a.respond_to?(:hour)
        interval_finish = time_a.to_s(:db)
      else # End-time is a day, so we look for reservations including this day
        interval_finish = (time_a+(1.day)).to_s(:db)
      end
      interval_start = time_b.to_s(:db)
    else 
      interval_start = time_a.to_s(:db)
      if time_b.respond_to?(:hour)
        interval_finish = time_b.to_s(:db)
      else # End-time is a day, so we look for reservations including this day
        interval_finish = (time_b+(1.day)).to_s(:db)
      end
    end    
    self.where("(start >= '#{interval_start}' AND start <= '#{interval_finish}')")
  end
  
  def self.find_reservations_beginning_in_month(month)
    self.find_reservations_beginning_in_timeslot(month.beginning_of_month, month.end_of_month)
  end
  def self.find_reservations_beginning_in_year(year)
    self.find_reservations_beginning_in_timeslot(year.beginning_of_year, year.end_of_year)
  end
  
  def self.reservations_for_user_in_timeslot(user, time_a, time_b)
    self.find_reservations_beginning_in_timeslot(time_a, time_b).select { |r| r.user.eql? user }
  end
  def self.reservations_for_user_in_month(user, month) 
    self.find_reservations_beginning_in_month(month).select { |r| r.user.eql? user }
  end
  def self.reservations_for_user_in_year(user, year) 
    self.find_reservations_beginning_in_year(year).select { |r| r.user.eql? user }
  end
  
  def self.find_reservations_on_date(date)
    from = DateTime.new(date.year, date.month, date.day, 0, 0, 0)
    to = DateTime.new(date.year, date.month, date.day, 23, 59, 59)
    reservations = self.find_reservations_in_timeslot(from, to)
    reservations.sort {|a,b| a.begin_on_day(date) <=> b.begin_on_day(date)}
  end
  
  def self.find_reservations_in_timeslot(time_a, time_b)
    if time_a > time_b
      if time_a.respond_to?(:hour)
        interval_finish = time_a.to_s(:db)
      else # End-time is a day, so we look for reservations including this day
        interval_finish = (time_a+(1.day)).to_s(:db)
      end
      interval_start = time_b.to_s(:db)
    else 
      interval_start = time_a.to_s(:db)
      if time_b.respond_to?(:hour)
        interval_finish = time_b.to_s(:db)
      else # End-time is a day, so we look for reservations including this day
        interval_finish = (time_b+(1.day)).to_s(:db)
      end
    end    
    self.where("(start <= '#{interval_start}' AND finish > '#{interval_start}') OR ('#{interval_start}' <= start AND '#{interval_finish}' > start)").order(:start)    
  end
  
  def begin_on_day(day)
    if start < day.beginning_of_day
      day.beginning_of_day
    else
      start
    end
  end
  
  def end_on_day(day)
    if finish > day.end_of_day
      day.end_of_day
    else
      finish
    end
  end
  
  def fills_complete_day?(day)
    start <= day.beginning_of_day && finish > day.end_of_day
  end
  
  def hours_on_day(day)
    if fills_complete_day?(day)
      24
    else
      e = end_on_day(day.to_datetime.in_time_zone)
      b = begin_on_day(day.to_datetime.in_time_zone)
      ((e-b)/60/60).round
    end
  end
  
  protected

  def <=> other
    start <=> other.start
  end


  def is_timeslot_exclusive?
    conflicting_reservations = Reservation.find_reservations_in_timeslot(start, finish)
    conflicting_reservations.delete(self) # Needed for validation on Updates, otherwise we conflict with our old version
    errors.add(:start, "Dieser Zeitabschnitt überlappt mit einer bestehenden Reservation") unless conflicting_reservations.empty?
    errors.add(:finish, "Dieser Zeitabschnitt überlappt mit einer bestehenden Reservation") unless conflicting_reservations.empty?
  end
    
  def is_timeslot_positive?
    errors.add(:finish, "muss zeitlich hinter dem Reservations-Beginn sein") if finish <= start
  end


  def is_reservation_not_longer_than_a_week?
    errors.add(:finish, "Anfang und Ende liegen zu weit auseinander. Das Brüschhüsli kann für maximal 7 Tage reserviert werden") if duration > 60 * 60 * 24 * 7
  end

end
