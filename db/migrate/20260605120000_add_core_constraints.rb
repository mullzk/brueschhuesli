# frozen_string_literal: true

class AddCoreConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :reservations, :start, false
    change_column_null :reservations, :finish, false
    change_column_null :reservations, :type_of_reservation, false

    add_index :users, :name, unique: true
    add_index :users, :email, unique: true
  end
end
