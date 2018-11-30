# == Schema Information
#
# Table name: users
#
#  id                  :bigint(8)        not null, primary key
#  email               :string
#  hasToChangePassword :boolean
#  hashed_password     :string
#  miteigentuemer      :boolean
#  name                :string
#  salt                :string
#  telefon             :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class User < ApplicationRecord
  has_many :reservations

  attr_accessor :password_confirmation
  validates_confirmation_of :password
  validates_uniqueness_of :name
  
  validates_presence_of :name, :email, :hashed_password, :salt
  
  def validate
    errors.add_to_base("Missing Passwort") if hashed_password.blank?
  end
  
  def password
    @password
  end
  
  def password=(pwd)
    @password = pwd
    return if pwd.blank?
    create_new_salt
    self.hashed_password = User.encrypted_password(self.password, self.salt)
  end
    
  def <=>(other)
    name<=>other.name
  end
  
  private
  
  
  def self.encrypted_password(password, salt)
    string_to_hash = password + "sdf" + salt
    Digest::SHA1.hexdigest(string_to_hash)
  end
  
  def create_new_salt
    self.salt = self.object_id.to_s + rand.to_s    
  end
  
  
  def self.authenticate(name, password)
    user = self.find_by_name(name)
    if user
      expected_password = encrypted_password(password, user.salt)
      if user.hashed_password != expected_password
        user = nil
      end
    end
    user
  end
  
end
