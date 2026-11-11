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

ActiveRecord::Schema[8.1].define(version: 2026_11_11_140000) do
  create_table "reservations", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.text "comment"
    t.boolean "is_exclusive"
    t.datetime "start", null: false
    t.datetime "finish", null: false
    t.string "type_of_reservation", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_reservations_on_user_id"
  end

  create_table "sessions", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "telefon"
    t.string "hashed_password"
    t.string "salt"
    t.boolean "has_to_change_password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "role", default: "member", null: false
    t.bigint "responsible_user_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["name"], name: "index_users_on_name", unique: true
    t.index ["responsible_user_id"], name: "index_users_on_responsible_user_id"
  end

  add_foreign_key "reservations", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "users", column: "responsible_user_id"
end
