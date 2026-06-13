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

require "test_helper"

class ReservationTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user, name: "Hans", password: "test1234")
  end

  # takes at("2010-02-01") or at("2010-02-01 14:30")
  def at(iso_formatted_date_or_datetime)
    DateTime.parse(iso_formatted_date_or_datetime)
  end

  test "a reservation finishing after it starts is valid" do
    reservation = build(:reservation, user: @user, start: at("2010-02-01 08:00"), finish: at("2010-02-01 10:00"))
    assert reservation.valid?
  end

  test "a reservation finishing before it starts is invalid" do
    reservation = build(:reservation, user: @user, start: at("2010-02-01 10:00"), finish: at("2010-02-01 08:00"))
    assert_not reservation.valid?
  end

  test "a reservation longer than a week is invalid" do
    reservation = build(:reservation, user: @user, start: at("2010-02-01 10:00"), finish: at("2010-02-10 08:00"))
    assert_not reservation.valid?
  end

  test "a slot not overlapping any reservation is valid" do
    create(:reservation, user: @user, start: at("2010-02-01 14:00"), finish: at("2010-02-01 18:00"))
    assert build(:reservation, user: @user, start: at("2010-02-01 08:00"), finish: at("2010-02-01 10:00")).valid?
    assert build(:reservation, user: @user, start: at("2010-02-01 19:00"), finish: at("2010-02-01 21:00")).valid?
  end

  test "a slot overlapping an existing reservation is invalid" do
    create(:reservation, user: @user, start: at("2010-02-01 14:00"), finish: at("2010-02-01 18:00"))
    assert_not build(:reservation, user: @user, start: at("2010-02-01 08:00"), finish: at("2010-02-01 15:00")).valid?, "overlapping the start"
    assert_not build(:reservation, user: @user, start: at("2010-02-01 08:00"), finish: at("2010-02-01 21:00")).valid?, "enclosing the slot"
    assert_not build(:reservation, user: @user, start: at("2010-02-01 17:00"), finish: at("2010-02-01 21:00")).valid?, "overlapping the end"
    assert_not build(:reservation, user: @user, start: at("2010-01-31 19:00"), finish: at("2010-02-03 21:00")).valid?, "spanning across the slot"
  end

  test "find all reservations an a day" do
     first_reservation = FactoryBot.create(:reservation, user: @user, start: DateTime.new(2019, 2, 1, 14, 00), finish: DateTime.new(2019, 2, 2, 18, 00), type_of_reservation: Reservation::KURZAUFENTHALT)
    second_reservation = FactoryBot.create(:reservation, user: @user, start: DateTime.new(2019, 2, 2, 20, 00), finish: DateTime.new(2019, 2, 3, 18, 00), type_of_reservation: Reservation::KURZAUFENTHALT)

    assert     Reservation.find_reservations_on_date(Date.new(2019, 1, 31)).empty?
    assert     Reservation.find_reservations_on_date(Date.new(2019, 2, 1)).include?(first_reservation)
    assert_not Reservation.find_reservations_on_date(Date.new(2019, 2, 1)).include?(second_reservation)
    assert     Reservation.find_reservations_on_date(Date.new(2019, 2, 2)).include?(first_reservation)
    assert     Reservation.find_reservations_on_date(Date.new(2019, 2, 2)).include?(second_reservation)
    assert_not Reservation.find_reservations_on_date(Date.new(2019, 2, 3)).include?(first_reservation)
    assert     Reservation.find_reservations_on_date(Date.new(2019, 2, 3)).include?(second_reservation)
    assert_not Reservation.find_reservations_on_date(Date.new(2019, 2, 4)).include?(second_reservation)
  end

  test "find reservations that span multiple days" do
    res =  FactoryBot.create(:reservation, user: @user, start: DateTime.new(2010, 2, 4, 8, 15), finish: DateTime.new(2010, 2, 7, 10, 0), type_of_reservation: Reservation::KURZAUFENTHALT)

    # Interesting Timeslot is bigger or equal than reservation
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 7), DateTime.new(2010, 2, 7, 23)).include?(res)
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 8), DateTime.new(2010, 2, 7, 23)).include?(res)
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 8, 14), DateTime.new(2010, 2, 7, 23)).include?(res)
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 8, 15), DateTime.new(2010, 2, 7, 23)).include?(res)
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 7), DateTime.new(2010, 2, 7, 11)).include?(res)
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 7), DateTime.new(2010, 2, 7, 10)).include?(res)

    # Interesting Timeslot collides on one side with reservation
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 8, 15), DateTime.new(2010, 2, 7, 9)).include?(res)
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 9), DateTime.new(2010, 2, 7, 23)).include?(res)

    # Interesting Timeslot is inside a reservation
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 9), DateTime.new(2010, 2, 7, 9)).include?(res)
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 10), DateTime.new(2010, 2, 4, 11)).include?(res)

    # The order is of no importance
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 11), DateTime.new(2010, 2, 4, 10)).include?(res)
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 6, 11), DateTime.new(2010, 2, 4, 10)).include?(res)

    # Timeslot before
    assert_not Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 7), DateTime.new(2010, 2, 4, 8)).include?(res)
    assert_not Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 7), DateTime.new(2010, 2, 4, 8, 15)).include?(res)
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 7), DateTime.new(2010, 2, 4, 9)).include?(res)

    # Timeslot after
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 7, 9), DateTime.new(2010, 2, 7, 12)).include?(res)
    assert_not Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 7, 10), DateTime.new(2010, 2, 7, 12)).include?(res)
    assert_not Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 7, 11), DateTime.new(2010, 2, 7, 12)).include?(res)
    assert_not Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 8, 8), DateTime.new(2010, 2, 9, 9)).include?(res)
  end

  test "find reservations in timeslot on one day" do
    r1 =  FactoryBot.create(:reservation, user: @user, start: DateTime.new(2010, 2, 4, 8, 15), finish: DateTime.new(2010, 2, 7, 10, 0), type_of_reservation: Reservation::KURZAUFENTHALT)
    r2 =  FactoryBot.create(:reservation, user: @user, start: DateTime.new(2010, 2, 8, 8, 15), finish: DateTime.new(2010, 2, 8, 10, 0), type_of_reservation: Reservation::KURZAUFENTHALT)
    r3 =  FactoryBot.create(:reservation, user: @user, start: DateTime.new(2010, 2, 8, 13, 0), finish: DateTime.new(2010, 2, 8, 15, 0), type_of_reservation: Reservation::KURZAUFENTHALT)

    assert_not Reservation.find_reservations_in_timeslot(Date.new(2010, 2, 2), Date.new(2010, 2, 3)).include?(r1)
    assert Reservation.find_reservations_in_timeslot(Date.new(2010, 2, 2), Date.new(2010, 2, 4)).include?(r1)
    assert Reservation.find_reservations_in_timeslot(Date.new(2010, 2, 4), Date.new(2010, 2, 6)).include?(r1)
    assert Reservation.find_reservations_in_timeslot(Date.new(2010, 2, 5), Date.new(2010, 2, 6)).include?(r1)
    assert Reservation.find_reservations_in_timeslot(Date.new(2010, 2, 5), Date.new(2010, 2, 9)).include?(r1)
    assert Reservation.find_reservations_in_timeslot(Date.new(2010, 2, 7), Date.new(2010, 2, 9)).include?(r1)
    assert_not Reservation.find_reservations_in_timeslot(Date.new(2010, 2, 8), Date.new(2010, 2, 9)).include?(r1)

    assert Reservation.find_reservations_in_timeslot(Date.new(2010, 2, 6), Date.new(2010, 2, 8)).include?(r2)
    assert Reservation.find_reservations_in_timeslot(Date.new(2010, 2, 8), Date.new(2010, 2, 8)).include?(r2)
    assert Reservation.find_reservations_in_timeslot(Date.new(2010, 2, 8), Date.new(2010, 2, 10)).include?(r2)
    assert_not Reservation.find_reservations_in_timeslot(Date.new(2010, 2, 9), Date.new(2010, 2, 10)).include?(r2)
  end

  test "long KURZAUFENTHALT should be interpreted as FERIENAUFENTHALT" do
    ruth = FactoryBot.create(:user, name: "Ruth", password: "test1234", miteigentuemer: true)
    r1 = Reservation.new(start: DateTime.new(2010, 6, 1, 12), finish: DateTime.new(2010, 6, 8, 11), user: ruth)
    r2 = Reservation.new(start: DateTime.new(2010, 6, 1, 12), finish: DateTime.new(2010, 6, 8, 12), user: ruth)
    r3 = Reservation.new(start: DateTime.new(2010, 6, 1, 12), finish: DateTime.new(2010, 6, 8, 13), user: ruth)
    [ r1, r2, r3 ].each do |r|
      r.type_of_reservation = Reservation::KURZAUFENTHALT
    end
    assert r1.valid?
    assert r2.valid?
    assert_not r3.valid? # Reservation is too long

    r1 = Reservation.new(start: DateTime.new(2010, 6, 1, 12), finish: DateTime.new(2010, 6, 8, 11), type_of_reservation: Reservation::KURZAUFENTHALT)
    assert_equal r1.classified_type, Reservation::FERIENAUFENTHALT
    r1 = Reservation.new(start: DateTime.new(2010, 6, 1, 12), finish: DateTime.new(2010, 6, 3, 12), type_of_reservation: Reservation::KURZAUFENTHALT)
    assert_equal r1.classified_type, Reservation::KURZAUFENTHALT
    r1 = Reservation.new(start: DateTime.new(2010, 6, 1, 12), finish: DateTime.new(2010, 6, 3, 13), type_of_reservation: Reservation::KURZAUFENTHALT)
    assert_equal r1.classified_type, Reservation::FERIENAUFENTHALT
    r1 = Reservation.new(start: DateTime.new(2010, 6, 1, 12), finish: DateTime.new(2010, 6, 2, 11), type_of_reservation: Reservation::FERIENAUFENTHALT)
    assert_equal r1.classified_type, Reservation::KURZAUFENTHALT
    r1 = Reservation.new(start: DateTime.new(2010, 6, 1, 12), finish: DateTime.new(2010, 6, 3, 12), type_of_reservation: Reservation::FERIENAUFENTHALT)
    assert_equal r1.classified_type, Reservation::FERIENAUFENTHALT
    r1 = Reservation.new(start: DateTime.new(2010, 6, 1, 12), finish: DateTime.new(2010, 6, 3, 11), type_of_reservation: Reservation::FERIENAUFENTHALT)
    assert_equal r1.classified_type, Reservation::KURZAUFENTHALT
  end

  test "classified_type can diverge from the stored column" do
    r = Reservation.new(start: DateTime.new(2010, 6, 1, 12), finish: DateTime.new(2010, 6, 8, 11), type_of_reservation: Reservation::KURZAUFENTHALT)
    assert_equal Reservation::KURZAUFENTHALT, r.type_of_reservation
    assert_equal Reservation::FERIENAUFENTHALT, r.classified_type
  end

  test "Reservations should be ordered by Start date" do
    r1 = FactoryBot.create(:reservation, start: DateTime.new(2010, 6, 5, 12), finish: DateTime.new(2010, 6, 6, 12))
    r2 = FactoryBot.create(:reservation, start: DateTime.new(2010, 6, 1, 12), finish: DateTime.new(2010, 6, 3, 11))
    r3 = FactoryBot.create(:reservation, start: DateTime.new(2010, 6, 3, 19), finish: DateTime.new(2010, 6, 4, 20))
    r4 = FactoryBot.create(:reservation, start: DateTime.new(2010, 6, 3, 12), finish: DateTime.new(2010, 6, 3, 18))
    reservations = Reservation.find_reservations_in_timeslot(Date.new(2010, 6, 1), Date.new(2010, 6, 10))
    assert_equal reservations.first, r2
    assert_equal reservations[1], r4
    assert_equal reservations[2], r3
    assert_equal reservations.last, r1
  end

  test "on_day? covers every day a reservation overlaps" do
    r = Reservation.new(start: DateTime.new(2019, 2, 1, 14), finish: DateTime.new(2019, 2, 3, 18))
    assert_not r.on_day?(Date.new(2019, 1, 31))
    assert     r.on_day?(Date.new(2019, 2, 1))
    assert     r.on_day?(Date.new(2019, 2, 2))
    assert     r.on_day?(Date.new(2019, 2, 3))
    assert_not r.on_day?(Date.new(2019, 2, 4))
  end

  test "calculare timespans on one particular day" do
    r = Reservation.new(start: DateTime.new(2010, 6, 1, 12), finish: DateTime.new(2010, 6, 3, 11))
    assert_equal r.begin_on_day(Date.new(2010, 6, 1)).hour, 12
    assert_equal r.begin_on_day(Date.new(2010, 6, 2)).hour, 0
    assert_equal r.begin_on_day(Date.new(2010, 6, 3)).hour, 0
    assert_equal r.end_on_day(Date.new(2010, 6, 1)).hour, 23
    assert_equal r.end_on_day(Date.new(2010, 6, 2)).hour, 23
    assert_equal r.end_on_day(Date.new(2010, 6, 3)).hour, 11

    assert_not r.fills_complete_day?(Date.new(2010, 6, 1))
    assert r.fills_complete_day?(Date.new(2010, 6, 2))
    assert_not r.fills_complete_day?(Date.new(2010, 6, 3))

    assert_equal r.hours_on_day(Date.new(2010, 6, 1)), 12
    assert_equal r.hours_on_day(Date.new(2010, 6, 2)), 24
    assert_equal r.hours_on_day(Date.new(2010, 6, 3)), 11

    r = Reservation.new(start: DateTime.new(2010, 6, 1, 1), finish: DateTime.new(2010, 6, 1, 24))
    assert_equal r.hours_on_day(Date.new(2010, 6, 1)), 23
    r = Reservation.new(start: DateTime.new(2010, 6, 1, 0), finish: DateTime.new(2010, 6, 1, 23))
    assert_equal r.hours_on_day(Date.new(2010, 6, 1)), 23
  end


  test "reservations beginning on timeslot for accounting" do
    stefan = FactoryBot.create(:user, name: "Stefan", password: "test1234")
    kaspar = FactoryBot.create(:user, name: "Kaspar", password: "test1234")
    ruth   = FactoryBot.create(:user, name: "Ruth", password: "test1234")

    res_kaspar1 = Reservation.create(start: DateTime.new(2010, 2, 1, 16), finish: DateTime.new(2010, 2, 1, 18), user: kaspar)
    res_ruth1   = Reservation.create(start: DateTime.new(2010, 2, 3, 8, 15), finish: DateTime.new(2010, 2, 3, 10), user: ruth)
    res_kaspar2 = Reservation.create(start: DateTime.new(2010, 2, 4, 8, 15), finish: DateTime.new(2010, 2, 7, 10), user: kaspar)
    res_kaspar3 = Reservation.create(start: DateTime.new(2010, 2, 8, 8, 15), finish: DateTime.new(2010, 2, 8, 10), user: kaspar)
    res_ruth2   = Reservation.create(start: DateTime.new(2010, 2, 8, 13), finish: DateTime.new(2010, 2, 8, 15), user: ruth)
    res_stefan  = Reservation.create(start: DateTime.new(2010, 2, 27, 13), finish: DateTime.new(2010, 3, 3, 15), user: stefan)

    [ res_kaspar1, res_kaspar2, res_kaspar3, res_ruth1, res_ruth2, res_stefan ].each do |reservation|
      reservation.type_of_reservation = Reservation::KURZAUFENTHALT
      reservation.save!
    end

    res = Reservation.find_reservations_beginning_in_timeslot(Date.new(2010, 2, 3), Date.new(2010, 2, 7))
    assert_not res.include?(res_kaspar1)
    assert     res.include?(res_ruth1)
    assert     res.include?(res_kaspar2)
    assert_not res.include?(res_kaspar3)
    assert_not res.include?(res_ruth2)

    res = Reservation.find_reservations_beginning_in_timeslot(Date.new(2010, 2, 4), Date.new(2010, 2, 8))
    assert_not res.include?(res_ruth1)
    assert     res.include?(res_kaspar3)
    assert     res.include?(res_ruth2)


    res = Reservation.find_reservations_beginning_in_timeslot(Date.new(2010, 2, 3), DateTime.new(2010, 2, 8, 12))
    assert_not res.include?(res_kaspar1)
    assert     res.include?(res_ruth1)
    assert     res.include?(res_kaspar2)
    assert     res.include?(res_kaspar3)
    assert_not res.include?(res_ruth2)

    res = Reservation.find_reservations_beginning_in_month(Date.new(2010, 2, 10))
    assert     res.include?(res_kaspar2)
    assert     res.include?(res_stefan)
    res = Reservation.find_reservations_beginning_in_month(Date.new(2010, 3, 10))
    assert_not res.include?(res_kaspar2)
    assert_not res.include?(res_stefan)

    res = Reservation.reservations_for_user_in_month(kaspar, Date.new(2010, 2, 10))
    assert     res.include?(res_kaspar1)
    assert_not res.include?(res_ruth1)
    assert     res.include?(res_kaspar2)
    assert     res.include?(res_kaspar3)
    assert_not res.include?(res_ruth2)

    res = Reservation.reservations_for_user_in_timeslot(kaspar, DateTime.new(2010, 2, 3), DateTime.new(2010, 2, 7))
    assert_not res.include?(res_kaspar1)
    assert_not res.include?(res_ruth1)
    assert     res.include?(res_kaspar2)
    assert_not res.include?(res_kaspar3)
    assert_not res.include?(res_ruth2)
  end


  test "Duration-Calculations for accounting" do
    r = Reservation.new(start: DateTime.new(2010, 6, 1, 14), finish: DateTime.new(2010, 6, 1, 15))
    assert_equal r.duration_in_days, 1
    assert_equal r.duration_rounded_to_hours, 1.hour
    assert_equal r.duration_in_8_hour_blocks, 1

    r = Reservation.new(start: DateTime.new(2010, 6, 1, 16), finish: DateTime.new(2010, 6, 2, 15))
    assert_equal r.duration_in_days, 2
    assert_equal r.duration_rounded_to_hours, 23.hours
    assert_equal r.duration_in_8_hour_blocks, 3

    r = Reservation.new(start: DateTime.new(2010, 6, 1, 0), finish: DateTime.new(2010, 6, 1).end_of_day)
    assert_equal r.duration_in_days, 1
    assert_equal r.duration_rounded_to_hours, 23.hours # Now of course, this looks like a bug! But we round to hours, an 24 hours would be a complete day, but we miss one second. Doesn't matter though.
    assert_equal r.duration_in_8_hour_blocks, 3

    r = Reservation.new(start: DateTime.new(2010, 6, 1, 0), finish: DateTime.new(2010, 6, 1, 24))
    assert_equal r.duration_in_days, 1 # Phase 2: a midnight finish no longer counts the next day
    assert_equal r.duration_rounded_to_hours, 24.hours
    assert_equal r.duration_in_8_hour_blocks, 3
  end



  test "Tariffing-System" do
    stefan = FactoryBot.create(:user, name: "Stefan", password: "test1234")
    ruth   = FactoryBot.create(:user, name: "Ruth", password: "test1234", miteigentuemer: true)


    r = Reservation.new(start: DateTime.new(2010, 6, 1, 14), finish: DateTime.new(2010, 6, 3, 15))
    r.user = stefan
    r.is_exclusive = false
    r.type_of_reservation = Reservation::KURZAUFENTHALT

    assert_equal r.duration_in_8_hour_blocks, 7
    assert_equal r.paid_blocks, 7

    r.user = ruth
    assert_equal r.duration_in_8_hour_blocks, 7
    assert_equal r.paid_blocks, 1  # as she is a miteigenuemer

    r.is_exclusive = true
    assert_equal r.paid_blocks, 7

    r = Reservation.new(start: DateTime.new(2010, 6, 1, 14), finish: DateTime.new(2010, 6, 3, 14))
    r.user = ruth
    r.is_exclusive = false
    r.type_of_reservation = Reservation::KURZAUFENTHALT
    assert_equal r.duration_in_8_hour_blocks, 6
    assert_equal r.paid_blocks, 0

    # 8-hour-fee: 15 Franken
    rate_hourly = 15
    rate_daily = 100
    rate_event = 200

    assert_equal r.billed_fee, 0*rate_hourly
    r.is_exclusive = true
    assert_equal r.billed_fee, 6*rate_hourly
    r.user = stefan
    assert_equal r.billed_fee, 6*rate_hourly
    r.type_of_reservation = Reservation::FERIENAUFENTHALT
    assert_equal r.billed_fee, 6*rate_hourly
    r.type_of_reservation = Reservation::GROSSANLASS
    assert_equal r.billed_fee, rate_event   ##### Is this a bug? GROSSANLASS should be maxed to 32 hours, this one is 48 hours ! Who cares
    r.type_of_reservation = Reservation::EXTERNE_NUTZUNG
    assert_equal r.billed_fee, 3*rate_daily
  end

  # EXTERNE_NUTZUNG is billed per calendar day touched: a stay spanning three
  # calendar dates bills 3 x 100 CHF. A finish exactly at midnight does not
  # count the following day.
  test "EXTERNE_NUTZUNG bills per calendar day" do
    r = Reservation.new(
      start: DateTime.new(2010, 6, 1, 14), finish: DateTime.new(2010, 6, 3, 14),
      user: @user, is_exclusive: true, type_of_reservation: Reservation::EXTERNE_NUTZUNG
    )
    assert_equal 3, r.duration_in_days
    assert_equal 300, r.billed_fee
  end

  # Reversed Date arguments must not crash (Rails 8 removed Date#to_s(:db)) and
  # must return the same set as ascending arguments.
  test "find_reservations_beginning_in_timeslot is argument-order independent" do
    r = Reservation.create!(user: @user, start: DateTime.new(2010, 2, 4, 8), finish: DateTime.new(2010, 2, 4, 10), type_of_reservation: Reservation::KURZAUFENTHALT)
    ascending = Reservation.find_reservations_beginning_in_timeslot(Date.new(2010, 2, 3), Date.new(2010, 2, 7))
    reversed  = Reservation.find_reservations_beginning_in_timeslot(Date.new(2010, 2, 7), Date.new(2010, 2, 3))
    assert_includes ascending, r
    assert_includes reversed, r
  end
end
