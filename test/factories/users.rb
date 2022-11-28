# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  name                   :string
#  email                  :string
#  telefon                :string
#  hashed_password        :string
#  salt                   :string
#  has_to_change_password :boolean
#  miteigentuemer         :boolean
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

FactoryBot.define do
  factory :user do
    factory :valid_user do
      sequence :name do |n|
        "Test-User Nr #{n}"
      end
      email { 'test@mail.com' }
      salt { 'pseudosalt' }
      hashed_password { 'pseudo-pw, not valid for login' }
    end
  end
end
