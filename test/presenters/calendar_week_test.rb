# frozen_string_literal: true

# Spec-Tests (auskommentiert) — Vorhaben 3, Schritt 2.
# Aktiviert mit dem Presenter `CalendarWeek` und dem serverseitigen
# Lane-Packing (ui-overhaul-spec.local.md §3). Bis dahin inert.
#
# require "test_helper"
#
# class CalendarWeekTest < ActiveSupport::TestCase
#   setup do
#     @user = create(:user)
#   end
#
#   # Juni 2026 beginnt an einem Montag: weeks[0]=1.–7., [1]=8.–14.,
#   # [2]=15.–21., [3]=22.–28., [4]=29.–30. (Spalten 1=Mo … 7=So).
#   def june_week(index)
#     CalendarMonth.for(Date.new(2026, 6, 1)).weeks[index]
#   end
#
#   def segment_for(week, reservation)
#     week.segments.find { |segment| segment.reservation == reservation }
#   end
#
#   test "weeks expose seven day cells" do
#     week = june_week(0)
#
#     assert_equal 7, week.days.size
#     assert_equal 1, week.days.first.date.day
#     assert_equal 7, week.days.last.date.day
#   end
#
#   test "a single-day reservation yields one segment in one column" do
#     reservation = create(:reservation, user: @user,
#                          start: at("2026-06-03 10:00"), finish: at("2026-06-03 18:00"))
#     segment = segment_for(june_week(0), reservation)
#
#     assert_equal 3, segment.start_col
#     assert_equal 3, segment.end_col
#     assert_not segment.continues_left?
#     assert_not segment.continues_right?
#     assert_equal 0, segment.lane
#   end
#
#   test "a multi-day reservation within a week spans columns" do
#     reservation = create(:reservation, user: @user,
#                          start: at("2026-06-09 14:00"), finish: at("2026-06-11 12:00"))
#     segment = segment_for(june_week(1), reservation)
#
#     assert_equal 2, segment.start_col # Dienstag
#     assert_equal 4, segment.end_col   # Donnerstag
#     assert_not segment.continues_left?
#     assert_not segment.continues_right?
#   end
#
#   test "a reservation across the week boundary splits into two segments" do
#     # Sa 27. → Mo 29. Juni: Segment in Woche 3 läuft rechts weiter,
#     # Segment in Woche 4 kommt von links.
#     reservation = create(:reservation, user: @user,
#                          start: at("2026-06-27 10:00"), finish: at("2026-06-29 16:00"))
#
#     first = segment_for(june_week(3), reservation)
#     assert_equal 6, first.start_col   # Samstag
#     assert_equal 7, first.end_col     # Sonntag
#     assert_not first.continues_left?
#     assert first.continues_right?
#
#     second = segment_for(june_week(4), reservation)
#     assert_equal 1, second.start_col  # Montag
#     assert_equal 1, second.end_col
#     assert second.continues_left?
#     assert_not second.continues_right?
#   end
#
#   test "overlapping reservations are packed into separate lanes" do
#     a = create(:reservation, user: @user,
#                start: at("2026-06-08 15:00"), finish: at("2026-06-10 12:00")) # Mo–Mi
#     b = create(:reservation, user: @user,
#                start: at("2026-06-10 16:00"), finish: at("2026-06-11 18:00")) # Mi–Do
#     week = june_week(1)
#
#     assert_equal 0, segment_for(week, a).lane
#     assert_equal 1, segment_for(week, b).lane
#   end
#
#   test "non-overlapping reservations share a lane" do
#     a = create(:reservation, user: @user,
#                start: at("2026-06-08 10:00"), finish: at("2026-06-09 12:00")) # Mo–Di
#     b = create(:reservation, user: @user,
#                start: at("2026-06-11 10:00"), finish: at("2026-06-12 12:00")) # Do–Fr
#     week = june_week(1)
#
#     assert_equal 0, segment_for(week, a).lane
#     assert_equal 0, segment_for(week, b).lane
#   end
#
#   test "exclusive flag is readable from the segment's reservation" do
#     exclusive = create(:reservation, user: @user, is_exclusive: true,
#                        start: at("2026-06-03 10:00"), finish: at("2026-06-03 18:00"))
#     open = create(:reservation, user: @user, is_exclusive: false,
#                   start: at("2026-06-05 10:00"), finish: at("2026-06-05 18:00"))
#     week = june_week(0)
#
#     assert segment_for(week, exclusive).reservation.is_exclusive
#     assert_not segment_for(week, open).reservation.is_exclusive
#   end
# end
