FactoryBot.define do
  factory :match_pick do
    association :user
    association :tournament
    association :golfer
    priority { 1 }
  end
end
