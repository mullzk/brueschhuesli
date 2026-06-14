# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string(255)
#  has_to_change_password :boolean
#  hashed_password        :string(255)
#  name                   :string(255)
#  password_digest        :string(255)
#  role                   :string(255)      default("member"), not null
#  salt                   :string(255)
#  telefon                :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  responsible_user_id    :bigint
#
# Indexes
#
#  index_users_on_email                (email) UNIQUE
#  index_users_on_name                 (name) UNIQUE
#  index_users_on_responsible_user_id  (responsible_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (responsible_user_id => users.id)
#

FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Test-User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "test1234" }
  end
end
