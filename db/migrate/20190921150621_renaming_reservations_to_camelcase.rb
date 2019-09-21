class RenamingReservationsToCamelcase < ActiveRecord::Migration[5.2]
  def up
    rename_column :reservations, :isExclusive, :is_exclusive
    rename_column :reservations, :typeOfReservation, :type_of_reservation
  end
  def down
    rename_column :reservations, :is_exclusive, :isExclusive
    rename_column :reservations, :type_of_reservation, :typeOfReservation
  end
end
