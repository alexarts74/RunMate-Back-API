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

ActiveRecord::Schema[7.0].define(version: 2025_02_07_191428) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "event_participations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_participations_on_event_id"
    t.index ["user_id", "event_id"], name: "index_event_participations_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_event_participations_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "name"
    t.datetime "start_date"
    t.string "location"
    t.float "distance"
    t.bigint "creator_id"
    t.float "latitude"
    t.float "longitude"
    t.text "description"
    t.integer "max_participants"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "level", default: 0
    t.string "cover_image"
    t.index ["creator_id"], name: "index_events_on_creator_id"
    t.index ["level"], name: "index_events_on_level"
    t.index ["start_date"], name: "index_events_on_start_date"
    t.index ["status"], name: "index_events_on_status"
  end

  create_table "group_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "running_group_id", null: false
    t.integer "role", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["running_group_id"], name: "index_group_memberships_on_running_group_id"
    t.index ["user_id", "running_group_id"], name: "index_group_memberships_on_user_id_and_running_group_id", unique: true
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "join_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "running_group_id", null: false
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
    t.index ["running_group_id"], name: "index_join_requests_on_running_group_id"
    t.index ["status"], name: "index_join_requests_on_status"
    t.index ["user_id", "running_group_id"], name: "index_join_requests_on_user_id_and_running_group_id", unique: true
    t.index ["user_id"], name: "index_join_requests_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.integer "sender_id", null: false
    t.integer "recipient_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "read", default: false
    t.bigint "running_group_id"
    t.string "message_type", default: "direct"
    t.index ["read"], name: "index_messages_on_read"
    t.index ["recipient_id"], name: "index_messages_on_recipient_id"
    t.index ["running_group_id"], name: "index_messages_on_running_group_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.string "body"
    t.boolean "read"
    t.string "notification_type"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["read"], name: "index_notifications_on_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "runner_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "actual_pace"
    t.integer "usual_distance"
    t.string "availability"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "objective"
    t.index ["user_id"], name: "index_runner_profiles_on_user_id"
  end

  create_table "running_groups", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "level"
    t.integer "max_members"
    t.string "location"
    t.float "latitude"
    t.float "longitude"
    t.bigint "creator_id"
    t.integer "status", default: 0
    t.string "cover_image"
    t.jsonb "weekly_schedule"
    t.integer "members_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0
    t.index ["creator_id"], name: "index_running_groups_on_creator_id"
    t.index ["level"], name: "index_running_groups_on_level"
    t.index ["status"], name: "index_running_groups_on_status"
  end

  create_table "running_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "pace"
    t.integer "distance"
    t.string "availability"
    t.string "level"
    t.string "preferred_gender"
    t.json "age_range"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_running_preferences_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.integer "age"
    t.string "gender"
    t.string "profile_image"
    t.text "bio"
    t.string "authentication_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "expo_push_token"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "city"
    t.string "department"
    t.string "country", default: "France"
    t.string "postcode"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["latitude", "longitude"], name: "index_users_on_latitude_and_longitude"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "event_participations", "events"
  add_foreign_key "event_participations", "users"
  add_foreign_key "events", "users", column: "creator_id"
  add_foreign_key "group_memberships", "running_groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "join_requests", "running_groups"
  add_foreign_key "join_requests", "users"
  add_foreign_key "messages", "running_groups"
  add_foreign_key "messages", "users", column: "recipient_id"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "runner_profiles", "users"
  add_foreign_key "running_groups", "users", column: "creator_id"
  add_foreign_key "running_preferences", "users"
end
