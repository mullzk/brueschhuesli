require "test_helper"

class YearlyStatementTest < ActiveSupport::TestCase
  test "groups reservations per user with count and summed fee, sorted by name" do
    bea = create(:user, name: "Bea")
    ada = create(:user, name: "Ada")
    create(:reservation, user: bea, start: at("2019-03-01 12:00"), finish: at("2019-03-01 20:00"))
    create(:reservation, user: ada, start: at("2019-05-01 12:00"), finish: at("2019-05-01 20:00"))
    create(:reservation, user: ada, start: at("2019-06-01 12:00"), finish: at("2019-06-01 20:00"))

    lines = YearlyStatement.for(Date.new(2019)).lines

    assert_equal [ ada, bea ], lines.map(&:user)
    assert_equal [ 2, 1 ], lines.map(&:reservation_count)
    assert_equal lines.first.fee, YearlyStatement.for(Date.new(2019)).lines.first.fee
  end

  test "excludes users without reservations in the year" do
    active = create(:user, name: "Active")
    create(:user, name: "Idle")
    create(:reservation, user: active, start: at("2019-03-01 12:00"), finish: at("2019-03-01 20:00"))

    lines = YearlyStatement.for(Date.new(2019)).lines

    assert_equal [ active ], lines.map(&:user)
  end

  test "counts reservations by their start year, not spans into the year" do
    user = create(:user)
    create(:reservation, user:, start: at("2019-06-01 12:00"), finish: at("2019-06-02 12:00"))
    create(:reservation, user:, start: at("2018-12-15 12:00"), finish: at("2018-12-16 12:00"))

    lines = YearlyStatement.for(Date.new(2019)).lines

    assert_equal 1, lines.sole.reservation_count
  end

  test "loads all users in a constant number of queries" do
    3.times do |i|
      user = create(:user, name: "User #{i}", email: "u#{i}@example.com")
      create(:reservation, user:, start: at("2019-0#{i + 1}-01 12:00"), finish: at("2019-0#{i + 1}-01 20:00"))
    end

    statement = YearlyStatement.for(Date.new(2019))

    assert_queries_count(2) { statement.lines }
  end
end
