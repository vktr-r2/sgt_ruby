require 'securerandom'

FactoryBot.define do
  factory :golfer do
    source_id { SecureRandom.base64(10) }
    sequence(:f_name) { |n| "Golfer#{n}" }
    sequence(:l_name) { |n| "Player#{n}" }
    last_active_tourney { create(:tournament).unique_id }
  end
end
