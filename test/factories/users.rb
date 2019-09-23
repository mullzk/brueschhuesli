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

FactoryBot.define do
  factory :user do 
    
    
    
  end
  
end
