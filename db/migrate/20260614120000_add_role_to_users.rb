# frozen_string_literal: true

class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :role, :string, null: false, default: "member"
    add_reference :users, :responsible_user, foreign_key: { to_table: :users }, null: true

    # Carry the existing Miteigentuemer flag over into the new role. Everyone
    # else (false / NULL) keeps the column default "member".
    execute "UPDATE users SET role = 'owner' WHERE miteigentuemer = TRUE"
  end

  def down
    remove_reference :users, :responsible_user, foreign_key: { to_table: :users }
    remove_column :users, :role
  end
end
