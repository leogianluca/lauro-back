FactoryBot.define do
  factory :investment_broker do
    sequence(:name) { |number| "Broker #{number}" }
    sequence(:email) { |number| "broker#{number}@example.com" }
    phone { "+1 555 0100" }
    company_name { "Florida Property Group" }
  end
end
