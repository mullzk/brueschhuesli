# == Schema Information
#
# Table name: reservations
#
#  id                  :bigint           not null, primary key
#  comment             :text(65535)
#  finish              :datetime         not null
#  is_exclusive        :boolean
#  start               :datetime         not null
#  type_of_reservation :string(255)      not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  user_id             :bigint
#
# Indexes
#
#  index_reservations_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

FactoryBot.define do
  factory :reservation do
    association :user, factory: :user
    start { DateTime.new(2019, 2, 1, 14, 0) }
    finish { DateTime.new(2019, 2, 1, 18, 0) }
    type_of_reservation { Reservation::KURZAUFENTHALT }

    # Legacy factory retained verbatim: the name says "kurzaufenthalt" but the
    # stored value is FERIENAUFENTHALT on purpose; reservation_test.rb depends
    # on this. To be renamed/corrected in Phase 1 under characterization tests.
    factory :kurzaufenthalt_for_testuser do
      association :user, factory: :valid_user
      type_of_reservation { Reservation::FERIENAUFENTHALT }
    end
  end
end
