# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  name                   :string
#  email                  :string
#  telefon                :string
#  hashed_password        :string
#  salt                   :string
#  has_to_change_password :boolean
#  miteigentuemer         :boolean
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class User < ApplicationRecord
  has_many :reservations

  attr_accessor :password_confirmation

  validates_confirmation_of :password
  validates_uniqueness_of :name

  validates_presence_of :name, :email, :hashed_password, :salt

  def validate
    errors.add_to_base('Missing Passwort') if hashed_password.blank?
  end

  attr_reader :password

  def password=(pwd)
    @password = pwd
    return if pwd.blank?

    create_new_salt
    self.hashed_password = User.encrypted_password(password, salt)
  end

  def <=>(other)
    name <=> other.name
  end

  private

  def self.encrypted_password(password, salt)
    string_to_hash = "#{password}sdf#{salt}"
    Digest::SHA1.hexdigest(string_to_hash)
  end

  def create_new_salt
    self.salt = object_id.to_s + rand.to_s
  end

  def self.authenticate(name, password)
    user = find_by_name(name)
    if user
      expected_password = encrypted_password(password, user.salt)
      user = nil if user.hashed_password != expected_password
    end
    user
  end
end
