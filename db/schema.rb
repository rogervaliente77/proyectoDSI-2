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

ActiveRecord::Schema[7.1].define(version: 2025_06_14_053936) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cajas", force: :cascade do |t|
    t.string "nombre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cajeros", force: :cascade do |t|
    t.string "nombre"
    t.bigint "caja_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["caja_id"], name: "index_cajeros_on_caja_id"
    t.index ["user_id"], name: "index_cajeros_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "quantity"
    t.float "price"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
  end

  create_table "pruebas", force: :cascade do |t|
    t.string "nombre"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sales", force: :cascade do |t|
    t.datetime "sold_at"
    t.string "client_name"
    t.bigint "caja_id", null: false
    t.bigint "cajero_id", null: false
    t.integer "client_id"
    t.float "total_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["caja_id"], name: "index_sales_on_caja_id"
    t.index ["cajero_id"], name: "index_sales_on_cajero_id"
  end

  create_table "user_sessions", force: :cascade do |t|
    t.string "session_token"
    t.datetime "expiration_time"
    t.bigint "user_id", null: false
    t.string "user_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "full_name"
    t.string "jwt_token"
    t.string "email"
    t.string "phone_number"
    t.string "password_digest"
    t.boolean "is_valid"
    t.string "session_token_id"
    t.integer "otp_code"
    t.boolean "is_admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "cliente"
    t.index ["email"], name: "index_users_on_email"
  end

  add_foreign_key "cajeros", "cajas"
  add_foreign_key "cajeros", "users"
  add_foreign_key "products", "categories"
  add_foreign_key "sales", "cajas"
  add_foreign_key "sales", "cajeros"
  add_foreign_key "user_sessions", "users"
end
