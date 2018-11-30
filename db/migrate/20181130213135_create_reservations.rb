class CreateReservations < ActiveRecord::Migration[5.2]
  def change
    create_table :reservations do |t|
      t.references :user, foreign_key: true
      t.text :comment
      t.boolean :isExclusive
      t.datetime :start
      t.datetime :finish
      t.string :typeOfReservation

      t.timestamps
    end
  end
end
