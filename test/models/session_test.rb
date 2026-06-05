require "test_helper"

class SessionTest < ActiveSupport::TestCase
  setup { @user = create(:user) }

  test "active excludes sessions older than the max age" do
    fresh = @user.sessions.create!
    stale = @user.sessions.create!
    stale.update_column(:created_at, (Session::MAX_AGE + 1.day).ago)

    assert_includes Session.active, fresh
    assert_not_includes Session.active, stale
    assert_includes Session.expired, stale
  end

  test "purge_expired deletes only expired sessions" do
    fresh = @user.sessions.create!
    stale = @user.sessions.create!
    stale.update_column(:created_at, (Session::MAX_AGE + 1.day).ago)

    assert_difference -> { Session.count }, -1 do
      Session.purge_expired
    end
    assert Session.exists?(fresh.id)
    assert_not Session.exists?(stale.id)
  end
end
