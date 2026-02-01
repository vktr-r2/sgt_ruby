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

ActiveRecord::Schema[8.0].define(version: 2026_02_01_172347) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "golfers", force: :cascade do |t|
    t.string "source_id", default: "", null: false
    t.string "f_name", default: "", null: false
    t.string "l_name", default: "", null: false
    t.string "last_active_tourney", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_id"], name: "index_golfers_on_source_id"
  end

  create_table "leaderboard_snapshots", force: :cascade do |t|
    t.bigint "tournament_id", null: false
    t.jsonb "leaderboard_data"
    t.integer "current_round"
    t.string "cut_line_score"
    t.integer "cut_line_count"
    t.datetime "fetched_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id"], name: "index_leaderboard_snapshots_on_tournament_id"
  end

  create_table "match_picks", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "tournament_id"
    t.bigint "golfer_id"
    t.integer "priority", null: false
    t.boolean "drafted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "original_golfer_id"
    t.integer "replaced_at_round"
    t.string "replacement_reason"
    t.index ["golfer_id"], name: "index_match_picks_on_golfer_id"
    t.index ["original_golfer_id"], name: "index_match_picks_on_original_golfer_id"
    t.index ["tournament_id"], name: "index_match_picks_on_tournament_id"
    t.index ["user_id"], name: "index_match_picks_on_user_id"
  end

  create_table "match_results", force: :cascade do |t|
    t.bigint "tournament_id"
    t.bigint "user_id"
    t.integer "total_score", null: false
    t.integer "place", null: false
    t.boolean "winner_picked", default: false, null: false
    t.integer "cuts_missed", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id"], name: "index_match_results_on_tournament_id"
    t.index ["user_id"], name: "index_match_results_on_user_id"
  end

  create_table "scores", force: :cascade do |t|
    t.bigint "match_pick_id"
    t.integer "score", default: 0
    t.integer "round", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "position"
    t.string "status", default: "active"
    t.string "thru"
    t.index ["match_pick_id"], name: "index_scores_on_match_pick_id"
    t.index ["status"], name: "index_scores_on_status"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "tournament_id", default: ""
    t.string "source_id", default: "", null: false
    t.string "name", default: "", null: false
    t.integer "year", null: false
    t.string "golf_course", default: "", null: false
    t.json "location"
    t.datetime "start_date", null: false
    t.datetime "end_date", null: false
    t.integer "week_number", null: false
    t.string "time_zone", default: ""
    t.string "format", default: "stroke", null: false
    t.boolean "major_championship", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "par", default: 72, null: false
    t.integer "purse"
    t.string "unique_id"
    t.index ["source_id"], name: "index_tournaments_on_source_id"
    t.index ["tournament_id", "year"], name: "index_tournaments_on_tournament_id_and_year"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.boolean "admin", default: false, null: false
    t.string "authentication_token"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "leaderboard_snapshots", "tournaments"
  add_foreign_key "match_picks", "golfers", column: "original_golfer_id", on_delete: :nullify
  add_foreign_key "match_picks", "golfers", on_delete: :cascade
  add_foreign_key "match_picks", "tournaments", on_delete: :cascade
  add_foreign_key "match_picks", "users", on_delete: :cascade
  add_foreign_key "match_results", "tournaments"
  add_foreign_key "match_results", "users"
  add_foreign_key "scores", "match_picks", on_delete: :cascade
end
