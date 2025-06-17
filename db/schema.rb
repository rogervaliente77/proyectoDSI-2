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

ActiveRecord::Schema[7.1].define(version: 2025_06_14_181101) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cajas", force: :cascade do |t|
    t.string "nombre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "caja_number"
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

  create_table "product_sales", force: :cascade do |t|
    t.bigint "sale_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.float "unit_price"
    t.float "discount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_sales_on_product_id"
    t.index ["sale_id"], name: "index_product_sales_on_sale_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "quantity"
    t.float "price"
    t.string "image_url"
    t.string "code"
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
    t.string "status"
    t.bigint "caja_id", null: false
    t.bigint "cajero_id", null: false
    t.integer "client_id"
    t.float "total_amount"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["caja_id"], name: "index_sales_on_caja_id"
    t.index ["cajero_id"], name: "index_sales_on_cajero_id"
  end

  create_table "user_sales", force: :cascade do |t|
    t.bigint "sale_id", null: false
    t.bigint "user_id", null: false
    t.datetime "sale_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sale_id"], name: "index_user_sales_on_sale_id"
    t.index ["user_id"], name: "index_user_sales_on_user_id"
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
  add_foreign_key "product_sales", "products"
  add_foreign_key "product_sales", "sales"
  add_foreign_key "products", "categories"
  add_foreign_key "sales", "cajas"
  add_foreign_key "sales", "cajeros"
  add_foreign_key "user_sales", "sales"
  add_foreign_key "user_sales", "users"
  add_foreign_key "user_sessions", "users"
end
