FactoryBot.define do
  factory :user do
    sequence(:email) { |number| "user#{number}@example.com" }
    password { "password123" }
    name { "Lauro Admin" }
    role { "viewer" }

    trait :admin do
      role { "admin" }
    end

    trait :editor do
      role { "editor" }
    end

    trait :viewer do
      role { "viewer" }
    end
  end
end
