# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_17_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"


  create_table "bookings", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.bigint "user_id", null: false
    t.datetime "borrowed_at", null: false
    t.datetime "returned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_bookings_on_active_book", unique: true, where: "(returned_at IS NULL)"
    t.index ["book_id"], name: "index_bookings_on_book_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
    t.check_constraint "returned_at IS NULL OR returned_at >= borrowed_at", name: "bookings_valid_return_date"
  end

  create_table "books", force: :cascade do |t|
    t.string "serial_number", null: false
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "author", null: false
    t.index ["serial_number"], name: "index_books_on_serial_number", unique: true
    t.check_constraint "serial_number::text ~ '^[0-9]{6}$'::text", name: "books_serial_number_six_digits"
  end

  create_table "users", force: :cascade do |t|
    t.string "card_number", null: false
    t.string "full_name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["card_number"], name: "index_users_on_card_number", unique: true
    t.check_constraint "card_number::text ~ '^[0-9]{6}$'::text", name: "users_card_number_six_digits"
  end

  add_foreign_key "bookings", "books"
  add_foreign_key "bookings", "users"

end
