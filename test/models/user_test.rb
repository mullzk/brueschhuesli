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
#  salt                   :string(255)
#  telefon                :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "Unknown User is not found" do
    dbuser = User.find_by_name("rumpelstilzchen")
    assert_not dbuser
  end

  test "User gets created, Passwort is not stored in clear-text" do
    user = FactoryBot.build(:user, name: "Stefan", email: "test@mail.com")
    user.password="test1234"
    user.save
    dbuser = User.find_by_name("Stefan")
    assert dbuser
    assert_not dbuser.password=="test1234"
  end


  test "authentication with correct password should pass" do
    user = FactoryBot.build(:user, name: "Stefan", email: "test@mail.com")
    user.password="test1234"
    user.save
    assert User.authenticate("Stefan", "test1234")
  end

  test "authentifcation with wrong password should be rejected" do
    user = FactoryBot.build(:user, name: "Stefan", email: "test@mail.com")
    user.password="test1234"
    user.save
    assert_not User.authenticate("Stefan", "test")
  end

  test "authentification with no password should be rejected" do
    user = FactoryBot.build(:user, name: "Stefan", email: "test@mail.com")
    user.password="test1234"
    user.save
    assert_not User.authenticate("Stefan", "")
  end

  # --- validations -----------------------------------------------------------

  test "name must be unique" do
    create(:user, name: "Hans")
    duplicate = build(:user, name: "Hans")
    assert_not duplicate.valid?
    assert duplicate.errors[:name].present?
  end

  test "name, email, hashed_password and salt are required" do
    user = User.new
    assert_not user.valid?
    assert user.errors[:name].present?
    assert user.errors[:email].present?
    assert user.errors[:hashed_password].present?
    assert user.errors[:salt].present?
  end

  # --- password= -------------------------------------------------------------

  test "blank password is ignored and leaves no hash" do
    user = User.new(name: "Blank", email: "blank@example.com")
    user.password = ""
    assert_nil user.hashed_password
    assert_nil user.salt
    assert_not user.valid? # hashed_password/salt presence not satisfied
  end

  test "nil password is ignored and leaves no hash" do
    user = User.new(name: "Nil", email: "nil@example.com")
    user.password = nil
    assert_nil user.hashed_password
    assert_nil user.salt
  end

  test "non-blank password populates hash and salt" do
    user = User.new(name: "Set", email: "set@example.com")
    user.password = "secret"
    assert user.hashed_password.present?
    assert user.salt.present?
  end

  test "password confirmation must match when present" do
    user = build(:user)
    user.password = "secret"
    user.password_confirmation = "different"
    assert_not user.valid?
    assert user.errors[:password_confirmation].present?

    user.password_confirmation = "secret"
    assert user.valid?
  end
end
