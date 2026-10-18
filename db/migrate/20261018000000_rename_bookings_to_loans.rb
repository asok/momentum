class RenameBookingsToLoans < ActiveRecord::Migration[8.1]
  def up
    rename_table :bookings, :loans
    rename_index :loans, :index_bookings_on_active_book, :index_loans_on_active_book
    execute "ALTER TABLE loans RENAME CONSTRAINT bookings_valid_return_date TO loans_valid_return_date"
  end

  def down
    execute "ALTER TABLE loans RENAME CONSTRAINT loans_valid_return_date TO bookings_valid_return_date"
    rename_index :loans, :index_loans_on_active_book, :index_bookings_on_active_book
    rename_table :loans, :bookings
  end
end
