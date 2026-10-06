FactoryBot.define do
  factory :investment_location do
    sequence(:name) { |number| "Location #{number}" }
    city { "Orlando" }
    state { "FL" }
    zip_code { "32801" }
    country { "US" }
  end
end
