# frozen_string_literal: true

class Renaming < ActiveRecord::Migration[5.2]
  def up
    rename_column :users, :hasToChangePassword, :has_to_change_password
  end

  def down
    rename_column :users, :has_to_change_password, :hasToChangePassword
  end
end
