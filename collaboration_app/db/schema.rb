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

ActiveRecord::Schema[8.0].define(version: 2025_08_30_091506) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "collaborations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "note_id", null: false
    t.integer "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id"], name: "index_collaborations_on_note_id"
    t.index ["role"], name: "index_collaborations_on_role"
    t.index ["user_id", "note_id"], name: "index_collaborations_on_user_id_and_note_id", unique: true
    t.index ["user_id"], name: "index_collaborations_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.string "title", null: false
    t.jsonb "content", default: {}, null: false
    t.bigint "owner_id", null: false
    t.jsonb "document_state", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content"], name: "index_notes_on_content", using: :gin
    t.index ["document_state"], name: "index_notes_on_document_state", using: :gin
    t.index ["owner_id"], name: "index_notes_on_owner_id"
  end

  create_table "operations", force: :cascade do |t|
    t.bigint "note_id", null: false
    t.bigint "user_id", null: false
    t.integer "operation_type", null: false
    t.integer "position", null: false
    t.text "content"
    t.datetime "timestamp", null: false
    t.boolean "applied", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id", "applied"], name: "index_operations_on_note_id_and_applied"
    t.index ["note_id", "timestamp"], name: "index_operations_on_note_id_and_timestamp"
    t.index ["note_id"], name: "index_operations_on_note_id"
    t.index ["operation_type"], name: "index_operations_on_operation_type"
    t.index ["user_id"], name: "index_operations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "avatar_url"
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "collaborations", "notes"
  add_foreign_key "collaborations", "users"
  add_foreign_key "notes", "users", column: "owner_id"
  add_foreign_key "operations", "notes"
  add_foreign_key "operations", "users"
end
