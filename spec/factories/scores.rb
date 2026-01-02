FactoryBot.define do
  factory :score do
    association :match_pick
    score { rand(65..75) }
    round { 1 }

    trait :excellent do
      score { rand(63..67) }
    end

    trait :average do
      score { rand(68..72) }
    end

    trait :poor do
      score { rand(73..78) }
    end

    trait :round_1 do
      round { 1 }
    end

    trait :round_2 do
      round { 2 }
    end

    trait :round_3 do
      round { 3 }
    end

    trait :round_4 do
      round { 4 }
    end

    trait :with_position do
      position { "T#{rand(1..20)}" }
      status { "active" }
    end

    trait :withdrawn do
      status { "wd" }
      position { "WD" }
    end

    trait :cut do
      status { "cut" }
      position { "CUT" }
    end
  end
end
