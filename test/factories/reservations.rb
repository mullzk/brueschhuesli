# == Schema Information
#
# Table name: reservations
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  comment             :text
#  is_exclusive        :boolean
#  start               :datetime
#  finish              :datetime
#  type_of_reservation :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_reservations_on_user_id  (user_id)
#

FactoryBot.define do
  factory :reservation do

    association :user, factory: :user
    
    factory :kurzaufenthalt_for_testuser do 
      association :user, factory: :valid_user
      type_of_reservation {Reservation::FERIENAUFENTHALT}
    end
  end
  
end
