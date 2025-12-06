FactoryBot.define do
  factory :match_result do
    association :user
    association :tournament
    total_score { rand(-10..10) }
    place { rand(1..4) }
    winner_picked { false }
    cuts_missed { 0 }

    trait :first_place do
      place { 1 }
      total_score { -15 }
      winner_picked { true }
    end

    trait :second_place do
      place { 2 }
      total_score { -10 }
    end

    trait :third_place do
      place { 3 }
      total_score { -5 }
    end

    trait :fourth_place do
      place { 4 }
      total_score { 0 }
    end

    trait :with_cuts do
      cuts_missed { rand(1..3) }
    end
  end
end
