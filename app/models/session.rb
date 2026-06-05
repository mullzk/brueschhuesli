class Session < ApplicationRecord
  belongs_to :user

  MAX_AGE = 30.days

  scope :active, -> { where(created_at: MAX_AGE.ago..) }
  scope :expired, -> { where(created_at: ..MAX_AGE.ago) }

  def self.purge_expired
    expired.delete_all
  end
end
