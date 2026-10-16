class CreateLibraryTables < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :serial_number, null: false
      t.string :title, null: false
      t.string :author, null: false
      t.timestamps
    end
    add_index :books, :serial_number, unique: true
    add_check_constraint :books, "serial_number ~ '^[0-9]{6}$'", name: "books_serial_number_six_digits"

    create_table :users do |t|
      t.string :card_number, null: false
      t.string :full_name, null: false
      t.string :email, null: false
      t.timestamps
    end
    add_index :users, :card_number, unique: true
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"
    add_check_constraint :users, "card_number ~ '^[0-9]{6}$'", name: "users_card_number_six_digits"

    create_table :bookings do |t|
      t.references :book, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :borrowed_at, null: false
      t.datetime :returned_at
      t.timestamps
    end
    add_index :bookings, :book_id, unique: true, where: "returned_at IS NULL", name: "index_bookings_on_active_book"
    add_check_constraint :bookings, "returned_at IS NULL OR returned_at >= borrowed_at", name: "bookings_valid_return_date"
  end
end
