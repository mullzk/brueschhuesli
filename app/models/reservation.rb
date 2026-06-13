# == Schema Information
#
# Table name: reservations
#
#  id                  :bigint           not null, primary key
#  comment             :text(65535)
#  finish              :datetime         not null
#  is_exclusive        :boolean
#  start               :datetime         not null
#  type_of_reservation :string(255)      not null
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
  KURZAUFENTHALT = "Kurzaufenthalt"
  FERIENAUFENTHALT = "Ferienaufenthalt"
  GROSSANLASS = "Grossanlass"
  EXTERNE_NUTZUNG = "Nutzung durch Dritte"
  TYPES = [ KURZAUFENTHALT, FERIENAUFENTHALT, GROSSANLASS, EXTERNE_NUTZUNG ].freeze

  LONG_STAY_THRESHOLD = 48.hours

  belongs_to :user
  validates :start, :finish, :type_of_reservation, presence: true
  validates :type_of_reservation, inclusion: { in: TYPES }, allow_blank: true
  validate :timeslot_exclusive?, :timeslot_positive?, :reservation_not_longer_than_a_week?

  def self.reservation_types
    TYPES.sort
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
    floor_to_hour(finish) - floor_to_hour(start)
  end

  def floor_to_hour(time)
    DateTime.new(time.year, time.month, time.day, time.hour, 0).in_time_zone
  end

  def duration_in_8_hour_blocks
    (duration_rounded_to_hours / 8.hours.to_i).ceil
  end

  def paid_blocks
    billing.paid_blocks
  end

  def billed_fee
    billing.fee
  end

  def billing
    ReservationBilling.new(
      type: classified_type,
      blocks: duration_in_8_hour_blocks,
      days: duration_in_days,
      miteigentuemer: user.miteigentuemer?,
      exclusive: is_exclusive?
    )
  end
  private :billing


  def classified_type
    saved = self[:type_of_reservation]
    if saved == KURZAUFENTHALT && duration > LONG_STAY_THRESHOLD
      FERIENAUFENTHALT
    elsif saved == FERIENAUFENTHALT && duration < LONG_STAY_THRESHOLD
      KURZAUFENTHALT
    else
      saved
    end
  end

  scope :beginning_in, ->(range) { where(start: range) }
  scope :overlapping, ->(range) { where("start < ? AND finish > ?", range.end, range.begin).order(:start) }
  scope :for_user, ->(user) { where(user: user) }

  # Builds an inclusive range from two endpoints given in any order. A Date upper
  # bound covers its whole day by extending to the next midnight; a DateTime is
  # already a precise instant. Active Record casts the bounds to the column type.
  def self.day_aware_range(time_a, time_b)
    lower, upper = [ time_a, time_b ].minmax
    upper += 1.day unless upper.respond_to?(:hour)
    lower..upper
  end
  private_class_method :day_aware_range

  # Reservations beginning in a timeslot: one spanning multiple months is reported
  # only in its first month. This keeps the tariff calculation much simpler.
  def self.find_reservations_beginning_in_timeslot(time_a, time_b)
    beginning_in(day_aware_range(time_a, time_b))
  end

  def self.find_reservations_beginning_in_month(month)
    find_reservations_beginning_in_timeslot(month.beginning_of_month, month.end_of_month)
  end
  def self.find_reservations_beginning_in_year(year)
    find_reservations_beginning_in_timeslot(year.beginning_of_year, year.end_of_year)
  end

  def self.reservations_for_user_in_timeslot(user, time_a, time_b)
    find_reservations_beginning_in_timeslot(time_a, time_b).for_user(user)
  end
  def self.reservations_for_user_in_month(user, month)
    find_reservations_beginning_in_month(month).for_user(user)
  end
  def self.reservations_for_user_in_year(user, year)
    find_reservations_beginning_in_year(year).for_user(user)
  end

  def self.find_reservations_on_date(date)
    find_reservations_in_timeslot(date, date).sort { |a, b| a.begin_on_day(date) <=> b.begin_on_day(date) }
  end

  def self.find_reservations_in_timeslot(time_a, time_b)
    overlapping(day_aware_range(time_a, time_b))
  end

  def begin_on_day(day)
    day_projection(day).begins_at
  end

  def end_on_day(day)
    day_projection(day).ends_at
  end

  def fills_complete_day?(day)
    day_projection(day).complete?
  end

  def on_day?(day)
    day_projection(day).overlaps?
  end

  def hours_on_day(day)
    day_projection(day).hours
  end

  def day_projection(day)
    ReservationDay.new(start: start, finish: finish, day: day)
  end
  private :day_projection

  protected

  def <=>(other)
    start <=> other.start
  end


  def timeslot_exclusive?
    conflicting_reservations = Reservation.find_reservations_in_timeslot(start, finish).to_a
    conflicting_reservations.delete(self) # Needed for validation on Updates, otherwise we conflict with our old version
    errors.add(:start, "Dieser Zeitabschnitt überlappt mit einer bestehenden Reservation") unless conflicting_reservations.empty?
    errors.add(:finish, "Dieser Zeitabschnitt überlappt mit einer bestehenden Reservation") unless conflicting_reservations.empty?
  end

  def timeslot_positive?
    errors.add(:finish, "muss zeitlich hinter dem Reservations-Beginn sein") if finish <= start
  end


  def reservation_not_longer_than_a_week?
    errors.add(:finish, "Anfang und Ende liegen zu weit auseinander. Das Brüschhüsli kann für maximal 7 Tage reserviert werden") if duration > 7.days
  end
end
