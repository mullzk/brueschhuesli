# == Schema Information
#
# Table name: reservations
#
#  id                  :bigint(8)        not null, primary key
#  comment             :text
#  finish              :datetime
#  is_exclusive        :boolean
#  start               :datetime
#  type_of_reservation :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  user_id             :bigint(8)
#
# Indexes
#
#  index_reservations_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)


FactoryBot.define do
  factory :reservation do

    association :user, factory: :user
    
    factory :kurzaufenthalt_for_testuser do 
      association :user, factory: :valid_user
      type_of_reservation {Reservation::FERIENAUFENTHALT}
    end
  end
  
end
