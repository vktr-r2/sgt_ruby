require 'securerandom'

FactoryBot.define do
  factory :tournament do
    tournament_id { rand(1000..9999) }            # Random tournId
    source_id { SecureRandom.base64(10) }         # Random unique "_id"
    name { "Genesis Invitational" }
    year { Date.today.year }
    golf_course { "Riviera Country Club" }
    week_number { Date.today.strftime("%V").to_i }
    purse { 8700000 }  # Example purse amount
    start_date { Date.today }
    end_date { Date.today + 4.days }
  end
end
=begin

    Schedule

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

=end
