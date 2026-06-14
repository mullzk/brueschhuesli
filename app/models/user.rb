# frozen_string_literal: true

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

class User < ApplicationRecord
  ROLE_LABELS = {
    "owner" => "Miteigentümer/in",
    "member" => "Nutzungsberechtigte/r",
    "external" => "Externe/r",
    "shared_account" => "Haus-Login"
  }.freeze

  enum :role, ROLE_LABELS.keys.index_with(&:itself), default: "member"

  has_many :reservations, dependent: :restrict_with_error
  has_many :sessions, dependent: :destroy
  has_many :dependents, class_name: "User", foreign_key: :responsible_user_id,
                        inverse_of: :responsible_user, dependent: :restrict_with_error
  belongs_to :responsible_user, class_name: "User", optional: true

  # validations: false because the built-in digest-presence check rejects
  # legacy users (bcrypt not set yet, only a SHA1 hash). We validate the
  # password ourselves, treating a legacy hash as a present password.
  has_secure_password validations: false

  validates :name, uniqueness: true
  validates :email, uniqueness: true
  validates :name, :email, presence: true
  validates :password, confirmation: true, allow_blank: true
  validate :password_must_be_set
  validates :responsible_user, presence: true, if: :external?
  validates :responsible_user, absence: true, unless: :external?
  validate :responsible_user_must_be_owner

  before_save :clear_legacy_password, if: -> { password_digest_changed? && password_digest.present? }

  def <=>(other)
    name <=> other.name
  end

  def role_label
    ROLE_LABELS.fetch(role)
  end

  def self.authenticate(login, password)
    user = find_by(name: login) || find_by(email: login)
    return nil unless user
    return user if user.authenticate(password)
    return user.rehash_legacy_password(password) if user.legacy_password?(password)

    nil
  end

  def legacy_password?(password)
    return false if salt.blank? || hashed_password.blank?

    ActiveSupport::SecurityUtils.secure_compare(self.class.legacy_hash(password, salt), hashed_password)
  end

  def rehash_legacy_password(password)
    update(password: password, hashed_password: nil, salt: nil)
    self
  end

  def self.legacy_hash(password, salt)
    Digest::SHA1.hexdigest("#{password}sdf#{salt}")
  end

  private

  def password_must_be_set
    return if password_digest.present? || hashed_password.present?

    errors.add(:password, :blank)
  end

  def responsible_user_must_be_owner
    return if responsible_user.blank?

    errors.add(:responsible_user, :invalid) unless responsible_user.owner?
  end

  def clear_legacy_password
    self.salt = nil
    self.hashed_password = nil
  end
end
