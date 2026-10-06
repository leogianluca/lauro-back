FactoryBot.define do
  factory :lead do
    sequence(:name) { |number| "Investor #{number}" }
    sequence(:email) { |number| "investor#{number}@example.com" }
    phone { "+1 407 555 0100" }
    source { "website" }
    message { "I would like to learn more." }
    metadata { { interest: "residential" } }
  end
end
