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

  test "a reservation finishing after it starts is valid" do
    reservation = build(:reservation, user: @user, start: at("2010-02-01 08:00"), finish: at("2010-02-01 10:00"))

    assert_predicate reservation, :valid?
  end

  test "a reservation finishing before it starts is invalid" do
    reservation = build(:reservation, user: @user, start: at("2010-02-01 10:00"), finish: at("2010-02-01 08:00"))

    assert_not reservation.valid?
  end

  test "a reservation longer than a week is invalid" do
    reservation = build(:reservation, user: @user, start: at("2010-02-01 10:00"), finish: at("2010-02-10 08:00"))

    assert_not reservation.valid?
  end

  test "a type outside the known list is invalid" do
    reservation = build(:reservation, user: @user, type_of_reservation: "Picknick")

    assert_not reservation.valid?
    assert_predicate reservation.errors[:type_of_reservation], :present?
  end

  test "every known type is valid" do
    Reservation::TYPES.each do |type|
      reservation = build(:reservation, user: @user, type_of_reservation: type)

      assert_predicate reservation, :valid?, "expected #{type} to be valid"
    end
  end

  test "a slot not overlapping any reservation is valid" do
    create(:reservation, user: @user, start: at("2010-02-01 14:00"), finish: at("2010-02-01 18:00"))

    assert_predicate build(:reservation, user: @user, start: at("2010-02-01 08:00"), finish: at("2010-02-01 10:00")), :valid?
    assert_predicate build(:reservation, user: @user, start: at("2010-02-01 19:00"), finish: at("2010-02-01 21:00")), :valid?
  end

  test "a slot overlapping an existing reservation is invalid" do
    create(:reservation, user: @user, start: at("2010-02-01 14:00"), finish: at("2010-02-01 18:00"))

    assert_not build(:reservation, user: @user, start: at("2010-02-01 08:00"), finish: at("2010-02-01 15:00")).valid?, "overlapping the start"
    assert_not build(:reservation, user: @user, start: at("2010-02-01 08:00"), finish: at("2010-02-01 21:00")).valid?, "enclosing the slot"
    assert_not build(:reservation, user: @user, start: at("2010-02-01 17:00"), finish: at("2010-02-01 21:00")).valid?, "overlapping the end"
    assert_not build(:reservation, user: @user, start: at("2010-01-31 19:00"), finish: at("2010-02-03 21:00")).valid?, "spanning across the slot"
  end

  test "find_reservations_on_date returns reservations overlapping that day" do
    spanning  = create(:reservation, user: @user, start: at("2019-02-01 14:00"), finish: at("2019-02-02 18:00"))
    following = create(:reservation, user: @user, start: at("2019-02-02 20:00"), finish: at("2019-02-03 18:00"))

    assert_empty    Reservation.find_reservations_on_date(on("2019-01-31"))
    assert_includes Reservation.find_reservations_on_date(on("2019-02-01")), spanning
    assert_not_includes Reservation.find_reservations_on_date(on("2019-02-01")), following
    assert_includes Reservation.find_reservations_on_date(on("2019-02-02")), spanning
    assert_includes Reservation.find_reservations_on_date(on("2019-02-02")), following
    assert_not_includes Reservation.find_reservations_on_date(on("2019-02-03")), spanning
    assert_includes Reservation.find_reservations_on_date(on("2019-02-03")), following
    assert_not_includes Reservation.find_reservations_on_date(on("2019-02-04")), following
  end

  test "find_reservations_in_timeslot finds any reservation the slot overlaps" do
    res = create(:reservation, user: @user, start: at("2010-02-04 08:15"), finish: at("2010-02-07 10:00"))

    assert_includes Reservation.find_reservations_in_timeslot(at("2010-02-04 07:00"), at("2010-02-07 23:00")), res
    assert_includes Reservation.find_reservations_in_timeslot(at("2010-02-04 08:00"), at("2010-02-07 23:00")), res
    assert_includes Reservation.find_reservations_in_timeslot(at("2010-02-04 08:14"), at("2010-02-07 23:00")), res
    assert_includes Reservation.find_reservations_in_timeslot(at("2010-02-04 08:15"), at("2010-02-07 23:00")), res
    assert_includes Reservation.find_reservations_in_timeslot(at("2010-02-04 07:00"), at("2010-02-07 11:00")), res
    assert_includes Reservation.find_reservations_in_timeslot(at("2010-02-04 07:00"), at("2010-02-07 10:00")), res
    assert_includes Reservation.find_reservations_in_timeslot(at("2010-02-04 08:15"), at("2010-02-07 09:00")), res
    assert_includes Reservation.find_reservations_in_timeslot(at("2010-02-04 09:00"), at("2010-02-07 23:00")), res
    assert_includes Reservation.find_reservations_in_timeslot(at("2010-02-04 09:00"), at("2010-02-07 09:00")), res
    assert_includes Reservation.find_reservations_in_timeslot(at("2010-02-04 10:00"), at("2010-02-04 11:00")), res
  end

  test "find_reservations_in_timeslot ignores the order of its arguments" do
    res = create(:reservation, user: @user, start: at("2010-02-04 08:15"), finish: at("2010-02-07 10:00"))

    assert_includes Reservation.find_reservations_in_timeslot(at("2010-02-04 11:00"), at("2010-02-04 10:00")), res
    assert_includes Reservation.find_reservations_in_timeslot(at("2010-02-06 11:00"), at("2010-02-04 10:00")), res
  end

  test "find_reservations_in_timeslot respects the slot boundaries" do
    res = create(:reservation, user: @user, start: at("2010-02-04 08:15"), finish: at("2010-02-07 10:00"))

    assert_not_includes Reservation.find_reservations_in_timeslot(at("2010-02-04 07:00"), at("2010-02-04 08:00")), res
    assert_not_includes Reservation.find_reservations_in_timeslot(at("2010-02-04 07:00"), at("2010-02-04 08:15")), res
    assert_includes Reservation.find_reservations_in_timeslot(at("2010-02-04 07:00"), at("2010-02-04 09:00")), res
    assert_includes Reservation.find_reservations_in_timeslot(at("2010-02-07 09:00"), at("2010-02-07 12:00")), res
    assert_not_includes Reservation.find_reservations_in_timeslot(at("2010-02-07 10:00"), at("2010-02-07 12:00")), res
    assert_not_includes Reservation.find_reservations_in_timeslot(at("2010-02-07 11:00"), at("2010-02-07 12:00")), res
    assert_not_includes Reservation.find_reservations_in_timeslot(at("2010-02-08 08:00"), at("2010-02-09 09:00")), res
  end

  test "find_reservations_in_timeslot treats date arguments as whole days" do
    long    = create(:reservation, user: @user, start: at("2010-02-04 08:15"), finish: at("2010-02-07 10:00"))
    morning = create(:reservation, user: @user, start: at("2010-02-08 08:15"), finish: at("2010-02-08 10:00"))

    assert_not_includes Reservation.find_reservations_in_timeslot(on("2010-02-02"), on("2010-02-03")), long
    assert_includes Reservation.find_reservations_in_timeslot(on("2010-02-02"), on("2010-02-04")), long
    assert_includes Reservation.find_reservations_in_timeslot(on("2010-02-04"), on("2010-02-06")), long
    assert_includes Reservation.find_reservations_in_timeslot(on("2010-02-05"), on("2010-02-06")), long
    assert_includes Reservation.find_reservations_in_timeslot(on("2010-02-05"), on("2010-02-09")), long
    assert_includes Reservation.find_reservations_in_timeslot(on("2010-02-07"), on("2010-02-09")), long
    assert_not_includes Reservation.find_reservations_in_timeslot(on("2010-02-08"), on("2010-02-09")), long

    assert_includes Reservation.find_reservations_in_timeslot(on("2010-02-06"), on("2010-02-08")), morning
    assert_includes Reservation.find_reservations_in_timeslot(on("2010-02-08"), on("2010-02-08")), morning
    assert_includes Reservation.find_reservations_in_timeslot(on("2010-02-08"), on("2010-02-10")), morning
    assert_not_includes Reservation.find_reservations_in_timeslot(on("2010-02-09"), on("2010-02-10")), morning
  end

  test "a reservation lasting exactly a week is valid, an hour more is not" do
    assert_predicate     build(:reservation, user: @user, start: at("2010-06-01 12:00"), finish: at("2010-06-08 11:00")), :valid?
    assert_predicate     build(:reservation, user: @user, start: at("2010-06-01 12:00"), finish: at("2010-06-08 12:00")), :valid?
    assert_not build(:reservation, user: @user, start: at("2010-06-01 12:00"), finish: at("2010-06-08 13:00")).valid?
  end

  test "classified_type swaps the stored type around the 48-hour threshold" do
    classify = lambda do |start, finish, stored|
      Reservation.new(start: at(start), finish: at(finish), type_of_reservation: stored).classified_type
    end

    assert_equal Reservation::FERIENAUFENTHALT, classify.call("2010-06-01 12:00", "2010-06-08 11:00", Reservation::KURZAUFENTHALT)
    assert_equal Reservation::KURZAUFENTHALT,   classify.call("2010-06-01 12:00", "2010-06-03 12:00", Reservation::KURZAUFENTHALT)
    assert_equal Reservation::FERIENAUFENTHALT, classify.call("2010-06-01 12:00", "2010-06-03 13:00", Reservation::KURZAUFENTHALT)
    assert_equal Reservation::KURZAUFENTHALT,   classify.call("2010-06-01 12:00", "2010-06-02 11:00", Reservation::FERIENAUFENTHALT)
    assert_equal Reservation::FERIENAUFENTHALT, classify.call("2010-06-01 12:00", "2010-06-03 12:00", Reservation::FERIENAUFENTHALT)
    assert_equal Reservation::KURZAUFENTHALT,   classify.call("2010-06-01 12:00", "2010-06-03 11:00", Reservation::FERIENAUFENTHALT)
  end

  test "classified_type can diverge from the stored column" do
    r = Reservation.new(start: at("2010-06-01 12:00"), finish: at("2010-06-08 11:00"), type_of_reservation: Reservation::KURZAUFENTHALT)

    assert_equal Reservation::KURZAUFENTHALT, r.type_of_reservation
    assert_equal Reservation::FERIENAUFENTHALT, r.classified_type
  end

  test "find_reservations_in_timeslot orders results by start" do
    fourth = create(:reservation, start: at("2010-06-05 12:00"), finish: at("2010-06-06 12:00"))
    first  = create(:reservation, start: at("2010-06-01 12:00"), finish: at("2010-06-03 11:00"))
    third  = create(:reservation, start: at("2010-06-03 19:00"), finish: at("2010-06-04 20:00"))
    second = create(:reservation, start: at("2010-06-03 12:00"), finish: at("2010-06-03 18:00"))

    ordered = Reservation.find_reservations_in_timeslot(on("2010-06-01"), on("2010-06-10"))

    assert_equal [ first, second, third, fourth ], ordered.to_a
  end

  test "on_day? covers every day a reservation overlaps" do
    r = Reservation.new(start: at("2019-02-01 14:00"), finish: at("2019-02-03 18:00"))

    assert_not r.on_day?(on("2019-01-31"))
    assert     r.on_day?(on("2019-02-01"))
    assert     r.on_day?(on("2019-02-02"))
    assert     r.on_day?(on("2019-02-03"))
    assert_not r.on_day?(on("2019-02-04"))
  end

  test "begin_on_day clamps the start to the given day" do
    r = Reservation.new(start: at("2010-06-01 12:00"), finish: at("2010-06-03 11:00"))

    assert_equal 12, r.begin_on_day(on("2010-06-01")).hour
    assert_equal 0,  r.begin_on_day(on("2010-06-02")).hour
    assert_equal 0,  r.begin_on_day(on("2010-06-03")).hour
  end

  test "end_on_day clamps the finish to the given day" do
    r = Reservation.new(start: at("2010-06-01 12:00"), finish: at("2010-06-03 11:00"))

    assert_equal 23, r.end_on_day(on("2010-06-01")).hour
    assert_equal 23, r.end_on_day(on("2010-06-02")).hour
    assert_equal 11, r.end_on_day(on("2010-06-03")).hour
  end

  test "fills_complete_day? is true only for fully covered days" do
    r = Reservation.new(start: at("2010-06-01 12:00"), finish: at("2010-06-03 11:00"))

    assert_not r.fills_complete_day?(on("2010-06-01"))
    assert     r.fills_complete_day?(on("2010-06-02"))
    assert_not r.fills_complete_day?(on("2010-06-03"))
  end

  test "hours_on_day counts the hours falling on the given day" do
    r = Reservation.new(start: at("2010-06-01 12:00"), finish: at("2010-06-03 11:00"))

    assert_equal 12, r.hours_on_day(on("2010-06-01"))
    assert_equal 24, r.hours_on_day(on("2010-06-02"))
    assert_equal 11, r.hours_on_day(on("2010-06-03"))

    assert_equal 23, Reservation.new(start: at("2010-06-01 01:00"), finish: at("2010-06-01 24:00")).hours_on_day(on("2010-06-01"))
    assert_equal 23, Reservation.new(start: at("2010-06-01 00:00"), finish: at("2010-06-01 23:00")).hours_on_day(on("2010-06-01"))
  end


  test "find_reservations_beginning_in_timeslot reports reservations by their start" do
    r = february_reservations

    found = Reservation.find_reservations_beginning_in_timeslot(on("2010-02-03"), on("2010-02-07"))

    assert_not_includes found, r[:kaspar_short]
    assert_includes found, r[:ruth_early]
    assert_includes found, r[:kaspar_span]
    assert_not_includes found, r[:kaspar_morning]
    assert_not_includes found, r[:ruth_afternoon]

    found = Reservation.find_reservations_beginning_in_timeslot(on("2010-02-04"), on("2010-02-08"))

    assert_not_includes found, r[:ruth_early]
    assert_includes found, r[:kaspar_morning]
    assert_includes found, r[:ruth_afternoon]

    found = Reservation.find_reservations_beginning_in_timeslot(on("2010-02-03"), at("2010-02-08 12:00"))

    assert_not_includes found, r[:kaspar_short]
    assert_includes found, r[:ruth_early]
    assert_includes found, r[:kaspar_span]
    assert_includes found, r[:kaspar_morning]
    assert_not_includes found, r[:ruth_afternoon]
  end

  test "find_reservations_beginning_in_month reports a reservation by its start month" do
    r = february_reservations

    february = Reservation.find_reservations_beginning_in_month(on("2010-02-10"))

    assert_includes february, r[:kaspar_span]
    assert_includes february, r[:stefan_month_end]

    march = Reservation.find_reservations_beginning_in_month(on("2010-03-10"))

    assert_not_includes march, r[:kaspar_span]
    assert_not_includes march, r[:stefan_month_end]
  end

  test "reservations_for_user finders scope by user and start" do
    r = february_reservations
    kaspar = r[:kaspar_span].user

    monthly = Reservation.reservations_for_user_in_month(kaspar, on("2010-02-10"))

    assert_includes monthly, r[:kaspar_short]
    assert_not_includes monthly, r[:ruth_early]
    assert_includes monthly, r[:kaspar_span]
    assert_includes monthly, r[:kaspar_morning]
    assert_not_includes monthly, r[:ruth_afternoon]

    slot = Reservation.reservations_for_user_in_timeslot(kaspar, at("2010-02-03"), at("2010-02-07"))

    assert_not_includes slot, r[:kaspar_short]
    assert_not_includes slot, r[:ruth_early]
    assert_includes slot, r[:kaspar_span]
    assert_not_includes slot, r[:kaspar_morning]
    assert_not_includes slot, r[:ruth_afternoon]
  end


  test "duration of a one-hour stay" do
    r = Reservation.new(start: at("2010-06-01 14:00"), finish: at("2010-06-01 15:00"))

    assert_equal 1, r.duration_in_days
    assert_equal 1.hour, r.duration_rounded_to_hours
    assert_equal 1, r.duration_in_8_hour_blocks
  end

  test "duration of an overnight stay spanning two days" do
    r = Reservation.new(start: at("2010-06-01 16:00"), finish: at("2010-06-02 15:00"))

    assert_equal 2, r.duration_in_days
    assert_equal 23.hours, r.duration_rounded_to_hours
    assert_equal 3, r.duration_in_8_hour_blocks
  end

  # Rounding to hours drops the final second, so a full day reads as 23 hours.
  test "duration of a stay until the end of the day" do
    r = Reservation.new(start: at("2010-06-01 00:00"), finish: at("2010-06-01").end_of_day)

    assert_equal 1, r.duration_in_days
    assert_equal 23.hours, r.duration_rounded_to_hours
    assert_equal 3, r.duration_in_8_hour_blocks
  end

  # A finish exactly at midnight does not count the following day.
  test "duration of a stay until midnight" do
    r = Reservation.new(start: at("2010-06-01 00:00"), finish: at("2010-06-01 24:00"))

    assert_equal 1, r.duration_in_days
    assert_equal 24.hours, r.duration_rounded_to_hours
    assert_equal 3, r.duration_in_8_hour_blocks
  end



  test "paid_blocks gives co-owners six free blocks on non-exclusive stays" do
    stefan = create(:user, name: "Stefan")
    ruth   = create(:user, name: "Ruth", miteigentuemer: true)
    seven_block_stay = lambda do |user, exclusive|
      Reservation.new(start: at("2010-06-01 14:00"), finish: at("2010-06-03 15:00"),
                      type_of_reservation: Reservation::KURZAUFENTHALT, user: user, is_exclusive: exclusive)
    end

    assert_equal 7, seven_block_stay.call(stefan, false).duration_in_8_hour_blocks
    assert_equal 7, seven_block_stay.call(stefan, false).paid_blocks  # not a co-owner
    assert_equal 1, seven_block_stay.call(ruth, false).paid_blocks    # co-owner, 7 - 6 free
    assert_equal 7, seven_block_stay.call(ruth, true).paid_blocks     # exclusive: no free blocks
  end

  test "billed_fee depends on the reservation type" do
    stefan = create(:user, name: "Stefan")
    ruth   = create(:user, name: "Ruth", miteigentuemer: true)

    r = Reservation.new(start: at("2010-06-01 14:00"), finish: at("2010-06-03 14:00"),
                        type_of_reservation: Reservation::KURZAUFENTHALT, user: ruth, is_exclusive: false)

    assert_equal 6, r.duration_in_8_hour_blocks

    assert_equal 0, r.billed_fee  # co-owner, non-exclusive: all 6 blocks free
    r.is_exclusive = true

    assert_equal 6 * 15, r.billed_fee
    r.user = stefan

    assert_equal 6 * 15, r.billed_fee
    r.type_of_reservation = Reservation::FERIENAUFENTHALT

    assert_equal 6 * 15, r.billed_fee
    r.type_of_reservation = Reservation::GROSSANLASS

    assert_equal 200, r.billed_fee  # flat fee regardless of duration
    r.type_of_reservation = Reservation::EXTERNE_NUTZUNG

    assert_equal 3 * 100, r.billed_fee  # three calendar days
  end

  # EXTERNE_NUTZUNG is billed per calendar day touched: a stay spanning three
  # calendar dates bills 3 x 100 CHF. A finish exactly at midnight does not
  # count the following day.
  test "EXTERNE_NUTZUNG bills per calendar day" do
    r = Reservation.new(
      start: at("2010-06-01 14:00"), finish: at("2010-06-03 14:00"),
      user: @user, is_exclusive: true, type_of_reservation: Reservation::EXTERNE_NUTZUNG
    )

    assert_equal 3, r.duration_in_days
    assert_equal 300, r.billed_fee
  end

  # Guards a Rails 8 regression: Date#to_s(:db) was removed, so reversed Date
  # arguments must still not crash and must return the ascending result.
  test "find_reservations_beginning_in_timeslot ignores the order of its arguments" do
    r = create(:reservation, user: @user, start: at("2010-02-04 08:00"), finish: at("2010-02-04 10:00"))
    ascending = Reservation.find_reservations_beginning_in_timeslot(on("2010-02-03"), on("2010-02-07"))
    reversed  = Reservation.find_reservations_beginning_in_timeslot(on("2010-02-07"), on("2010-02-03"))

    assert_includes ascending, r
    assert_includes reversed, r
  end

  private

  def february_reservations
    kaspar = create(:user, name: "Kaspar")
    ruth   = create(:user, name: "Ruth")
    stefan = create(:user, name: "Stefan")
    {
      kaspar_short:     create(:reservation, user: kaspar, start: at("2010-02-01 16:00"), finish: at("2010-02-01 18:00")),
      ruth_early:       create(:reservation, user: ruth,   start: at("2010-02-03 08:15"), finish: at("2010-02-03 10:00")),
      kaspar_span:      create(:reservation, user: kaspar, start: at("2010-02-04 08:15"), finish: at("2010-02-07 10:00")),
      kaspar_morning:   create(:reservation, user: kaspar, start: at("2010-02-08 08:15"), finish: at("2010-02-08 10:00")),
      ruth_afternoon:   create(:reservation, user: ruth,   start: at("2010-02-08 13:00"), finish: at("2010-02-08 15:00")),
      stefan_month_end: create(:reservation, user: stefan, start: at("2010-02-27 13:00"), finish: at("2010-03-03 15:00"))
    }
  end
end
