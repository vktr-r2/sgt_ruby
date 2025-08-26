FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    admin { false }
    authentication_token { nil }
    
    trait :admin do
      admin { true }
      name { "Admin User" }
    end
    
    trait :with_token do
      after(:create) do |user|
        user.ensure_authentication_token!
      end
    end
  end
end