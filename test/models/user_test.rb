# == Schema Information
#
# Table name: users
#
#  id                     :bigint(8)        not null, primary key
#  email                  :string
#  has_to_change_password :boolean
#  hashed_password        :string
#  miteigentuemer         :boolean
#  name                   :string
#  salt                   :string
#  telefon                :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "Unknown User is not found" do
    dbuser = User.find_by_name("rumpelstilzchen")
    assert_not dbuser
  end

  test "User gets created, Passwort is not stored in clear-text" do
    user = FactoryBot.build(:user, name:"Stefan", email:"test@mail.com")
    user.password="test1234"
    user.save
    dbuser = User.find_by_name("Stefan")
    assert dbuser
    assert_not dbuser.password=="test1234"
  end


  test "authentication with correct password should pass" do
    user = FactoryBot.build(:user, name:"Stefan", email:"test@mail.com")
    user.password="test1234"
    user.save
    assert User.authenticate("Stefan", "test1234")
  end

  test "authentifcation with wrong password should be rejected" do
    user = FactoryBot.build(:user, name:"Stefan", email:"test@mail.com")
    user.password="test1234"
    user.save
    assert_not User.authenticate("Stefan", "test")
  end
  
  test "authentification with no password should be rejected" do
    user = FactoryBot.build(:user, name:"Stefan", email:"test@mail.com")
    user.password="test1234"
    user.save
    assert_not User.authenticate("Stefan", "")
  end
 end
