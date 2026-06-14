# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id         :bigint           not null, primary key
#  ip_address :string(255)
#  user_agent :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_sessions_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Session < ApplicationRecord
  belongs_to :user

  MAX_AGE = 30.days

  scope :active, -> { where(created_at: MAX_AGE.ago..) }
  scope :expired, -> { where(created_at: ..MAX_AGE.ago) }

  def self.purge_expired
    expired.delete_all
  end
end
