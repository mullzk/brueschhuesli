# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :telefon
      t.string :hashed_password
      t.string :salt
      t.boolean :hasToChangePassword
      t.boolean :miteigentuemer

      t.timestamps
    end
  end
end
