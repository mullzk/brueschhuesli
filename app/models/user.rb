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

class User < ApplicationRecord
  has_many :reservations
  has_many :sessions, dependent: :destroy

  has_secure_password

  validates_uniqueness_of :name
  validates_uniqueness_of :email
  validates_presence_of :name, :email

  def <=>(other)
    name<=>other.name
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
    Digest::SHA1.hexdigest(password + "sdf" + salt)
  end
end
