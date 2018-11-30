# == Schema Information
#
# Table name: users
#
#  id                  :bigint(8)        not null, primary key
#  email               :string
#  hasToChangePassword :boolean
#  hashed_password     :string
#  miteigentuemer      :boolean
#  name                :string
#  salt                :string
#  telefon             :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "basic fixtures functionality" do
    assert users(:ruth).name.eql?("Ruth Mueller")
  end
  
  test "Authentification and Password Hashing" do
    assert_equal User.authenticate("Stefan Mueller", "password"), users(:stefan)
    assert_nil User.authenticate("Stefan Mueller", "wrong_password")
  end
 end
