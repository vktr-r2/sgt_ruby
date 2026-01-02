FactoryBot.define do
  factory :match_pick do
    association :user
    association :tournament
    association :golfer
    priority { 1 }

    trait :replaced do
      original_golfer_id { create(:golfer).id }
      replaced_at_round { 2 }
      replacement_reason { "wd" }
    end

    trait :early_replacement do
      original_golfer_id { create(:golfer).id }
      replaced_at_round { 1 }
      replacement_reason { "wd_early" }
    end
  end
end
