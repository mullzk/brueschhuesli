# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string(255)
#  has_to_change_password :boolean
#  hashed_password        :string(255)
#  miteigentuemer         :boolean
#  name                   :string(255)
#  password_digest        :string(255)
#  role                   :string(255)      default("member"), not null
#  salt                   :string(255)
#  telefon                :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  responsible_user_id    :bigint
#
# Indexes
#
#  index_users_on_email                (email) UNIQUE
#  index_users_on_name                 (name) UNIQUE
#  index_users_on_responsible_user_id  (responsible_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (responsible_user_id => users.id)
#

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "Unknown User is not found" do
    dbuser = User.find_by(name: "rumpelstilzchen")

    assert_not dbuser
  end

  test "a saved user stores its password hashed, not in clear text" do
    user = FactoryBot.build(:user, name: "Stefan", email: "test@mail.com")
    user.password = "test1234"
    user.save
    dbuser = User.find_by(name: "Stefan")

    assert dbuser
    assert_not dbuser.password == "test1234"
  end

  test "authentication with the correct password passes" do
    user = FactoryBot.build(:user, name: "Stefan", email: "test@mail.com")
    user.password = "test1234"
    user.save

    assert User.authenticate("Stefan", "test1234")
  end

  test "authentication with a wrong password is rejected" do
    user = FactoryBot.build(:user, name: "Stefan", email: "test@mail.com")
    user.password = "test1234"
    user.save

    assert_not User.authenticate("Stefan", "test")
  end

  test "authentication with no password is rejected" do
    user = FactoryBot.build(:user, name: "Stefan", email: "test@mail.com")
    user.password = "test1234"
    user.save

    assert_not User.authenticate("Stefan", "")
  end

  test "authenticate works by name or by email" do
    create(:user, name: "Dora", email: "dora@example.com", password: "secret123")

    assert User.authenticate("Dora", "secret123")
    assert User.authenticate("dora@example.com", "secret123")
    assert_not User.authenticate("Dora", "wrong")
  end

  test "legacy SHA1 user is transparently rehashed to bcrypt on login" do
    user = make_legacy_user("oldsecret")

    assert User.authenticate("Legacy", "oldsecret")
    user.reload

    assert_predicate user.password_digest, :present?
    assert_nil user.salt
    assert_nil user.hashed_password
    assert User.authenticate("Legacy", "oldsecret")
    assert_not User.authenticate("Legacy", "wrong")
  end

  test "legacy user with wrong password is rejected and left untouched" do
    user = make_legacy_user("oldsecret")

    assert_not User.authenticate("Legacy", "wrong")
    user.reload

    assert_nil user.password_digest
    assert_equal "legacy-salt", user.salt
    assert_equal User.legacy_hash("oldsecret", "legacy-salt"), user.hashed_password
  end

  # --- validations -----------------------------------------------------------

  test "name must be unique" do
    create(:user, name: "Hans")
    duplicate = build(:user, name: "Hans")

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:name], :present?
  end

  test "email must be unique" do
    create(:user, email: "shared@example.com")
    duplicate = build(:user, email: "shared@example.com")

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:email], :present?
  end

  test "name, email and password are required" do
    user = User.new

    assert_not user.valid?
    assert_predicate user.errors[:name], :present?
    assert_predicate user.errors[:email], :present?
    assert_predicate user.errors[:password], :present?
  end

  # --- password --------------------------------------------------------------

  test "blank password leaves no digest and is invalid" do
    user = User.new(name: "Blank", email: "blank@example.com")
    user.password = ""

    assert_nil user.password_digest
    assert_not user.valid?
    assert_predicate user.errors[:password], :present?
  end

  test "nil password leaves no digest" do
    user = User.new(name: "Nil", email: "nil@example.com")
    user.password = nil

    assert_nil user.password_digest
  end

  test "non-blank password populates the digest" do
    user = User.new(name: "Set", email: "set@example.com")
    user.password = "secret"

    assert_predicate user.password_digest, :present?
  end

  test "password confirmation must match when present" do
    user = build(:user)
    user.password = "secret"
    user.password_confirmation = "different"

    assert_not user.valid?
    assert_predicate user.errors[:password_confirmation], :present?

    user.password_confirmation = "secret"

    assert_predicate user, :valid?
  end

  test "a legacy user without a bcrypt digest stays valid and editable" do
    user = make_legacy_user("oldsecret")

    assert_predicate user, :valid?
    user.email = "moved@example.com"

    assert_predicate user, :valid?
  end

  test "setting a new password clears the legacy hash" do
    user = make_legacy_user("oldsecret")
    user.update!(password: "brandnew")

    assert_nil user.salt
    assert_nil user.hashed_password
    assert_predicate user.password_digest, :present?
  end

  test "a user with reservations cannot be destroyed" do
    user = create(:user)
    create(:reservation, user: user)

    assert_not user.destroy
    assert User.exists?(user.id)
  end

  # --- role model (Vorhaben #1) ----------------------------------------------

  test "a new user defaults to the member role" do
    assert_predicate build(:user), :member?
  end

  test "role predicates reflect the assigned role" do
    assert_predicate build(:user, role: :owner), :owner?
    assert_not build(:user, role: :owner).member?
  end

  test "role_label returns the German label" do
    assert_equal "Miteigentümer/in", build(:user, role: :owner).role_label
    assert_equal "Haus-Login", build(:user, role: :shared_account).role_label
  end

  test "ROLE_LABELS covers every enum role" do
    assert_equal User.roles.keys.sort, User::ROLE_LABELS.keys.map(&:to_s).sort
  end

  test "an external user requires a responsible owner" do
    external = build(:user, role: :external, responsible_user: nil)

    assert_not external.valid?
    assert_predicate external.errors[:responsible_user], :present?
  end

  test "the responsible user must itself be an owner" do
    member = create(:user, role: :member)
    external = build(:user, role: :external, responsible_user: member)

    assert_not external.valid?
  end

  test "an external user with a responsible owner is valid" do
    owner = create(:user, role: :owner)
    external = build(:user, role: :external, responsible_user: owner)

    assert_predicate external, :valid?
  end

  test "non-external roles must not have a responsible user" do
    owner = create(:user, role: :owner)
    member = build(:user, role: :member, responsible_user: owner)

    assert_not member.valid?
    assert_predicate member.errors[:responsible_user], :present?
  end

  private

  def make_legacy_user(password, salt: "legacy-salt")
    user = User.create!(name: "Legacy", email: "legacy@example.com", password: "temporary")
    user.update_columns(password_digest: nil, salt: salt,
                        hashed_password: User.legacy_hash(password, salt))
    user
  end
end
