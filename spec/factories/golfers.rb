require 'securerandom'

FactoryBot.define do
  factory :golfer do
    source_id { SecureRandom.base64(10) }
    f_name { "Viktor" }
    l_name { "Ristic" }
    last_active_tourney { SecureRandom.base64(10) }
  end
end
