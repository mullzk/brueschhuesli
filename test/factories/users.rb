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
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#  index_users_on_name   (name) UNIQUE
#

FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Test-User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    # Drives the password= setter, which populates hashed_password + salt.
    password { "test1234" }

    # Legacy factory retained verbatim: it sets hashed_password/salt directly
    # (overriding the parent password=) and is depended on via
    # :kurzaufenthalt_for_testuser. To be revisited in Phase 1.
    factory :valid_user do
      salt { "pseudosalt" }
      hashed_password { "pseudo-pw, not valid for login" }
    end
  end
end
