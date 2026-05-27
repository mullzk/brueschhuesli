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

FactoryBot.define do
  factory :user do 
    
    factory :valid_user do
      sequence :name do |n|
        "Test-User Nr #{n}"
      end
      email {"test@mail.com"}
      salt {"pseudosalt"}
      hashed_password {"pseudo-pw, not valid for login"}
    end
    
  end
  
end
