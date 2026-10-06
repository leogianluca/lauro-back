FactoryBot.define do
  factory :newsletter_subscriber do
    sequence(:email) { |number| "subscriber#{number}@example.com" }
    source { "homepage" }
    subscribed_at { Time.current }

    trait :unsubscribed do
      status { "unsubscribed" }
      subscribed_at { 2.days.ago }
      unsubscribed_at { 1.day.ago }
    end
  end
end
