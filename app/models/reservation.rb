# == Schema Information
#
# Table name: reservations
#
#  id                  :bigint           not null, primary key
#  comment             :text(65535)
#  finish              :datetime
#  is_exclusive        :boolean
#  start               :datetime
#  type_of_reservation :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  user_id             :bigint
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
    @reservation_types.sort { |a, b| a[1]<=>b[1] }
  end


  def duration
    finish-start
  end

  def duration_in_days
    # Billed per calendar day touched. A reservation ending exactly at midnight
    # does not count the following day (it only touches that day's first instant).
    last_day = finish == finish.beginning_of_day ? finish.to_date - 1 : finish.to_date
    (last_day - start.to_date).to_i + 1
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
    billing.paid_blocks
  end

  def billed_fee
    billing.fee
  end

  def billing
    ReservationBilling.new(
      type: type_of_reservation,
      blocks: duration_in_8_hour_blocks,
      days: duration_in_days,
      miteigentuemer: user.miteigentuemer?,
      exclusive: is_exclusive?
    )
  end
  private :billing


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

  def self.normalize_interval(time_a, time_b)
    lower, upper = time_a > time_b ? [ time_b, time_a ] : [ time_a, time_b ]
    [ lower_bound(lower), upper_bound(upper) ]
  end

  def self.lower_bound(date_or_time)
    date_or_time.to_formatted_s(:db)
  end

  def self.upper_bound(date_or_time)
    # A Date's upper bound is the next day. DateTime already is a precise instant.
    date_or_time += 1.day unless date_or_time.respond_to?(:hour)
    date_or_time.to_formatted_s(:db)
  end
  private_class_method :normalize_interval, :lower_bound, :upper_bound

  # Returns only reservations with beginning in a timeslot, e.g. Reservations that span multiple months are reported only in the first month. This makes calculating the tariffs much easier
  def self.find_reservations_beginning_in_timeslot(time_a, time_b)
    interval_start, interval_finish = normalize_interval(time_a, time_b)
    self.where("start >= ? AND start <= ?", interval_start, interval_finish)
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
    reservations.sort { |a, b| a.begin_on_day(date) <=> b.begin_on_day(date) }
  end

  def self.find_reservations_in_timeslot(time_a, time_b)
    interval_start, interval_finish = normalize_interval(time_a, time_b)
    self.where("(start <= ? AND finish > ?) OR (? <= start AND ? > start)", interval_start, interval_start, interval_start, interval_finish).order(:start)
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

  def <=>(other)
    start <=> other.start
  end


  def is_timeslot_exclusive?
    conflicting_reservations = Reservation.find_reservations_in_timeslot(start, finish).to_a
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
