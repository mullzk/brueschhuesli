# frozen_string_literal: true

class RemoveMiteigentuemerFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :miteigentuemer, :boolean
  end
end
