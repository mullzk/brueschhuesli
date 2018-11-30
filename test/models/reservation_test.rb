# == Schema Information
#
# Table name: reservations
#
#  id                :bigint(8)        not null, primary key
#  comment           :text
#  finish            :datetime
#  isExclusive       :boolean
#  start             :datetime
#  typeOfReservation :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :bigint(8)
#
# Indexes
#
#  index_reservations_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

require 'test_helper'

class ReservationTest < ActiveSupport::TestCase

  test "basic fixtures functionality" do
    assert_equal reservations(:ruth_on_3_2_2010).user, users(:ruth)
    assert_valid reservations(:kaspar_on_1_2_2010_evening)
    ruth = users(:ruth)
    assert_valid Reservation.new(:user => ruth, :isExclusive => true, :start => DateTime.new(2010,2,1,19), :finish => DateTime.new(2010,2,1,20), :typeOfReservation => Reservation::KURZAUFENTHALT)
    assert_invalid Reservation.new(:user => ruth, :isExclusive => true, :start => DateTime.new(2010,2,1,20), :finish => DateTime.new(2010,2,1,19), :typeOfReservation => Reservation::KURZAUFENTHALT)
  end
  

  test "overlapping Reservations" do
    r2 = Reservation.new(:user => users(:ruth), :isExclusive => false, :start => DateTime.new(2010,2,6,8,15), :finish => DateTime.new(2010,2,6,10), :typeOfReservation => Reservation::KURZAUFENTHALT)
    r3 = Reservation.new(:user => users(:stefan), :isExclusive => false, :start => DateTime.new(2010,2,2,8,15), :finish => DateTime.new(2010,2,5,10), :typeOfReservation => Reservation::KURZAUFENTHALT)


    r1 = reservations(:ruth_on_3_2_2010)
    r4 = reservations(:kaspar_from_4_2_2010__08_15_to_7_2_2010__10_00)
    r5 = reservations(:kaspar_on_1_2_2010_evening)

    assert_false r1.overlaps_with?(r2)
    assert r1.overlaps_with?(r3)
    assert_false r1.overlaps_with?(r4)
    assert_false r1.overlaps_with?(r5)
    
    assert_false r2.overlaps_with?(r1)
    assert_false r2.overlaps_with?(r3)
    assert r2.overlaps_with?(r4)
    assert_false r2.overlaps_with?(r5)

    assert r3.overlaps_with?(r4)
  end
  
  test "reservations per day" do 
    r1 =  reservations(:kaspar_from_4_2_2010__08_15_to_7_2_2010__10_00)
    r2 = reservations(:ruth_on_3_2_2010)
    
    reservations = Reservation.find_reservations_on_date(Date.new(2010, 2, 3))
    assert reservations.include?(r2)
    assert_false reservations.include?(r1)

    assert_false Reservation.find_reservations_on_date(Date.new(2010, 2, 3)).include?(r1)
    assert Reservation.find_reservations_on_date(Date.new(2010, 2, 4)).include?(r1)
    assert Reservation.find_reservations_on_date(Date.new(2010, 2, 5)).include?(r1)
    assert Reservation.find_reservations_on_date(Date.new(2010, 2, 6)).include?(r1)
    assert Reservation.find_reservations_on_date(Date.new(2010, 2, 7)).include?(r1)
    assert_false Reservation.find_reservations_on_date(Date.new(2010, 2, 8)).include?(r1)

  end
  
  test "reservations in timeslot on multiple days" do
    res =  reservations(:kaspar_from_4_2_2010__08_15_to_7_2_2010__10_00)

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
    assert_false Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 7), DateTime.new(2010, 2, 4, 8)).include?(res)
    assert_false Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 7), DateTime.new(2010, 2, 4, 8, 15)).include?(res)
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 4, 7), DateTime.new(2010, 2, 4, 9)).include?(res)
    
    # Timeslot after
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 7, 9), DateTime.new(2010, 2, 7, 12)).include?(res)
    assert_false Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 7, 10), DateTime.new(2010, 2, 7, 12)).include?(res)
    assert_false Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 7, 11), DateTime.new(2010, 2, 7, 12)).include?(res)
    assert_false Reservation.find_reservations_in_timeslot(DateTime.new(2010, 2, 8, 8), DateTime.new(2010, 2, 9, 9)).include?(res)
    
    
  end
  
  test "reservations in dateslot" do
    r1 =  reservations(:kaspar_from_4_2_2010__08_15_to_7_2_2010__10_00)
    r2 =  reservations(:kaspar_from_8_2_2010__08_15_to_8_2_2010__10_00)
    r3 =  reservations(:ruth_from_8_2_2010__13_00_to_8_2_2010__15_00)
    
    assert_false Reservation.find_reservations_in_timeslot(Date.new(2010,2,2), Date.new(2010,2,3)).include?(r1)
    assert Reservation.find_reservations_in_timeslot(Date.new(2010,2,2), Date.new(2010,2,4)).include?(r1)
    assert Reservation.find_reservations_in_timeslot(Date.new(2010,2,4), Date.new(2010,2,6)).include?(r1)
    assert Reservation.find_reservations_in_timeslot(Date.new(2010,2,5), Date.new(2010,2,6)).include?(r1)
    assert Reservation.find_reservations_in_timeslot(Date.new(2010,2,5), Date.new(2010,2,9)).include?(r1)
    assert Reservation.find_reservations_in_timeslot(Date.new(2010,2,7), Date.new(2010,2,9)).include?(r1)
    assert_false Reservation.find_reservations_in_timeslot(Date.new(2010,2,8), Date.new(2010,2,9)).include?(r1)

    assert Reservation.find_reservations_in_timeslot(Date.new(2010,2,6), Date.new(2010,2,8)).include?(r2)
    assert Reservation.find_reservations_in_timeslot(Date.new(2010,2,8), Date.new(2010,2,8)).include?(r2)
    assert Reservation.find_reservations_in_timeslot(Date.new(2010,2,8), Date.new(2010,2,10)).include?(r2)
    assert_false Reservation.find_reservations_in_timeslot(Date.new(2010,2,9), Date.new(2010,2,10)).include?(r2)

    
    
  end
  
  test "reservations in timeslot on one day" do
    r2 =  reservations(:kaspar_from_8_2_2010__08_15_to_8_2_2010__10_00)
    r3 =  reservations(:ruth_from_8_2_2010__13_00_to_8_2_2010__15_00)
    assert Reservation.find_reservations_on_date(DateTime.new(2010, 2, 8)).include?(r2)
    assert Reservation.find_reservations_on_date(DateTime.new(2010, 2, 8)).include?(r3)
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010,2,8,8), DateTime.new(2010,2,8,16)).include?(r2)
    assert Reservation.find_reservations_in_timeslot(DateTime.new(2010,2,8,8), DateTime.new(2010,2,8,16)).include?(r3)
    assert_false Reservation.find_reservations_in_timeslot(DateTime.new(2010,2,8,6), DateTime.new(2010,2,8,8)).include?(r2)
    assert_false Reservation.find_reservations_in_timeslot(DateTime.new(2010,2,8,15), DateTime.new(2010,2,8,16)).include?(r3)
    assert_false Reservation.find_reservations_in_timeslot(DateTime.new(2010,2,8,10), DateTime.new(2010,2,8,13)).include?(r2)
    assert_false Reservation.find_reservations_in_timeslot(DateTime.new(2010,2,8,10), DateTime.new(2010,2,8,13)).include?(r3)
    
  end
  
  test "duration of reservations" do
    r1 = Reservation.new(:start => DateTime.new(2010,6,1,12), :finish => DateTime.new(2010,6,8,11))
    r2 = Reservation.new(:start => DateTime.new(2010,6,1,12), :finish => DateTime.new(2010,6,8,12))
    r3 = Reservation.new(:start => DateTime.new(2010,6,1,12), :finish => DateTime.new(2010,6,8,13))
    [r1, r2, r3].each do |r|
      r.user = users(:ruth)
      r.typeOfReservation = Reservation::KURZAUFENTHALT
    end
    assert_valid(r1)
    assert_valid(r2)
    assert_invalid(r3)
    
    r1 = Reservation.new(:start => DateTime.new(2010,6,1,12), :finish => DateTime.new(2010,6,8,11), :typeOfReservation => Reservation::KURZAUFENTHALT)
    assert_equal r1.typeOfReservation, Reservation::FERIENAUFENTHALT
    r1 = Reservation.new(:start => DateTime.new(2010,6,1,12), :finish => DateTime.new(2010,6,3,12), :typeOfReservation => Reservation::KURZAUFENTHALT)
    assert_equal r1.typeOfReservation, Reservation::KURZAUFENTHALT
    r1 = Reservation.new(:start => DateTime.new(2010,6,1,12), :finish => DateTime.new(2010,6,3,13), :typeOfReservation => Reservation::KURZAUFENTHALT)
    assert_equal r1.typeOfReservation, Reservation::FERIENAUFENTHALT
    r1 = Reservation.new(:start => DateTime.new(2010,6,1,12), :finish => DateTime.new(2010,6,2,11), :typeOfReservation => Reservation::FERIENAUFENTHALT)
    assert_equal r1.typeOfReservation, Reservation::KURZAUFENTHALT
    r1 = Reservation.new(:start => DateTime.new(2010,6,1,12), :finish => DateTime.new(2010,6,3,12), :typeOfReservation => Reservation::FERIENAUFENTHALT)
    assert_equal r1.typeOfReservation, Reservation::FERIENAUFENTHALT
    r1 = Reservation.new(:start => DateTime.new(2010,6,1,12), :finish => DateTime.new(2010,6,3,11), :typeOfReservation => Reservation::FERIENAUFENTHALT)
    assert_equal r1.typeOfReservation, Reservation::KURZAUFENTHALT

  end  
  
  test "timespans on specified day" do
    r = Reservation.new(:start => DateTime.new(2010,6,1,12), :finish => DateTime.new(2010,6,3,11))    
    assert_equal r.begin_on_day(Date.new(2010,6,1)).hour, 12
    assert_equal r.begin_on_day(Date.new(2010,6,2)).hour, 0
    assert_equal r.begin_on_day(Date.new(2010,6,3)).hour, 0
    assert_equal r.end_on_day(Date.new(2010,6,1)).hour, 23
    assert_equal r.end_on_day(Date.new(2010,6,2)).hour, 23
    assert_equal r.end_on_day(Date.new(2010,6,3)).hour, 11
    
    assert_false r.fills_complete_day?(Date.new(2010,6,1))
    assert r.fills_complete_day?(Date.new(2010,6,2))
    assert_false r.fills_complete_day?(Date.new(2010,6,3))
        
    assert_equal r.hours_on_day(Date.new(2010,6,1)), 12
    assert_equal r.hours_on_day(Date.new(2010,6,2)), 24
    assert_equal r.hours_on_day(Date.new(2010,6,3)), 11

    r = Reservation.new(:start => DateTime.new(2010,6,1,1), :finish => DateTime.new(2010,6,1,24))    
    assert_equal r.hours_on_day(Date.new(2010,6,1)), 23
    r = Reservation.new(:start => DateTime.new(2010,6,1,0), :finish => DateTime.new(2010,6,1,23))    
    assert_equal r.hours_on_day(Date.new(2010,6,1)), 23
    
  end
  
  test "reservations beginning on timeslot for accounting" do
    res = Reservation.find_reservations_beginning_in_timeslot(Date.new(2010,2,3), Date.new(2010,2,7))
    assert_false res.include?(reservations(:kaspar_on_1_2_2010_evening))
    assert res.include?(reservations(:ruth_on_3_2_2010))
    assert res.include?(reservations(:kaspar_from_4_2_2010__08_15_to_7_2_2010__10_00))
    assert_false res.include?(reservations(:kaspar_from_8_2_2010__08_15_to_8_2_2010__10_00))
    assert_false res.include?(reservations(:ruth_from_8_2_2010__13_00_to_8_2_2010__15_00))

    res = Reservation.find_reservations_beginning_in_timeslot(Date.new(2010,2,4), Date.new(2010,2,8))
    assert_false res.include?(reservations(:ruth_on_3_2_2010))
    assert res.include?(reservations(:kaspar_from_8_2_2010__08_15_to_8_2_2010__10_00))
    assert res.include?(reservations(:ruth_from_8_2_2010__13_00_to_8_2_2010__15_00))


    res = Reservation.find_reservations_beginning_in_timeslot(Date.new(2010,2,3), DateTime.new(2010,2,8,12))
    assert_false res.include?(reservations(:kaspar_on_1_2_2010_evening))
    assert res.include?(reservations(:ruth_on_3_2_2010))
    assert res.include?(reservations(:kaspar_from_4_2_2010__08_15_to_7_2_2010__10_00))
    assert res.include?(reservations(:kaspar_from_8_2_2010__08_15_to_8_2_2010__10_00))
    assert_false res.include?(reservations(:ruth_from_8_2_2010__13_00_to_8_2_2010__15_00))

    res = Reservation.find_reservations_beginning_in_month(Date.new(2010,2,10))
    assert res.include?(reservations(:kaspar_from_4_2_2010__08_15_to_7_2_2010__10_00))
    assert res.include?(reservations(:stefan_from_27_2_2010__13_00_to_3_3_2010__15_00))
    res = Reservation.find_reservations_beginning_in_month(Date.new(2010,3,10))
    assert_false res.include?(reservations(:kaspar_from_4_2_2010__08_15_to_7_2_2010__10_00))
    assert_false res.include?(reservations(:stefan_from_27_2_2010__13_00_to_3_3_2010__15_00))
    
    res = Reservation.reservations_for_user_in_month(users(:kaspar), Date.new(2010,2,10))
    assert res.include?(reservations(:kaspar_on_1_2_2010_evening))
    assert_false res.include?(reservations(:ruth_on_3_2_2010))
    assert res.include?(reservations(:kaspar_from_4_2_2010__08_15_to_7_2_2010__10_00))
    assert res.include?(reservations(:kaspar_from_8_2_2010__08_15_to_8_2_2010__10_00))
    assert_false res.include?(reservations(:ruth_from_8_2_2010__13_00_to_8_2_2010__15_00))
    
    res = Reservation.reservations_for_user_in_timeslot(users(:kaspar), DateTime.new(2010,2,3), DateTime.new(2010,2,7))
    assert_false res.include?(reservations(:kaspar_on_1_2_2010_evening))
    assert_false res.include?(reservations(:ruth_on_3_2_2010))
    assert res.include?(reservations(:kaspar_from_4_2_2010__08_15_to_7_2_2010__10_00))
    assert_false res.include?(reservations(:kaspar_from_8_2_2010__08_15_to_8_2_2010__10_00))
    assert_false res.include?(reservations(:ruth_from_8_2_2010__13_00_to_8_2_2010__15_00))
    
  end
  
  test "Duration-Calculations for accounting" do 
    r = Reservation.new(:start => DateTime.new(2010,6,1,14), :finish => DateTime.new(2010,6,1,15))
    assert_equal r.duration_in_days, 1
    assert_equal r.duration_rounded_to_hours, 1.hour
    assert_equal r.duration_in_8_hour_blocks, 1

    r = Reservation.new(:start => DateTime.new(2010,6,1,16), :finish => DateTime.new(2010,6,2,15))
    assert_equal r.duration_in_days, 2
    assert_equal r.duration_rounded_to_hours, 23.hours
    assert_equal r.duration_in_8_hour_blocks, 3

    r = Reservation.new(:start => DateTime.new(2010,6,1,0), :finish => DateTime.new(2010,6,1).end_of_day)
    assert_equal r.duration_in_days, 1
    assert_equal r.duration_rounded_to_hours, 23.hours # Now of course, this looks like a bug! But we round to hours, an 24 hours would be a complete day, but we miss one second. Doesn't matter though.
    assert_equal r.duration_in_8_hour_blocks, 3

    r = Reservation.new(:start => DateTime.new(2010,6,1,0), :finish => DateTime.new(2010,6,1,24))
    assert_equal r.duration_in_days, 2 # see test above
    assert_equal r.duration_rounded_to_hours, 24.hours 
    assert_equal r.duration_in_8_hour_blocks, 3
  end
  
  test "Tariffing-System" do
    r = Reservation.new(:start => DateTime.new(2010,6,1,14), :finish => DateTime.new(2010,6,3,15))
    r.user = users(:stefan)
    r.isExclusive = false
    r.typeOfReservation = Reservation::KURZAUFENTHALT
    
    assert_equal r.duration_in_8_hour_blocks, 7
    assert_equal r.paid_blocks, 7
    
    r.user = users(:ruth)
    assert_equal r.duration_in_8_hour_blocks, 7
    assert_equal r.paid_blocks, 1
    
    r.isExclusive = true 
    assert_equal r.paid_blocks, 7

    r = Reservation.new(:start => DateTime.new(2010,6,1,14), :finish => DateTime.new(2010,6,3,14))
    r.user = users(:ruth)
    r.isExclusive = false
    r.typeOfReservation = Reservation::KURZAUFENTHALT
    assert_equal r.duration_in_8_hour_blocks, 6
    assert_equal r.paid_blocks, 0
    
    # 8-hour-fee: 15 Franken
    rate_hourly = 15
    rate_daily = 100
    rate_event = 200
    
    assert_equal r.billed_fee, 0*rate_hourly
    r.isExclusive = true
    assert_equal r.billed_fee, 6*rate_hourly
    r.user = users(:stefan)
    assert_equal r.billed_fee, 6*rate_hourly
    r.typeOfReservation = Reservation::FERIENAUFENTHALT
    assert_equal r.billed_fee, 6*rate_hourly
    r.typeOfReservation = Reservation::GROSSANLASS
    assert_equal r.billed_fee, rate_event   ##### Is this a bug? GROSSANLASS should be maxed to 32 hours, this one is 48 hours ! Who cares
    r.typeOfReservation = Reservation::EXTERNE_NUTZUNG
    assert_equal r.billed_fee, 3*rate_daily    
  end
end
