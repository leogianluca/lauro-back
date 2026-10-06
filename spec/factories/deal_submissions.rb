FactoryBot.define do
  factory :deal_submission do
    sequence(:submitter_name) { |number| "Broker #{number}" }
    sequence(:submitter_email) { |number| "broker#{number}@example.com" }
    company_name { "Florida Property Group" }
    category { "commercial" }
    asset_type { "retail" }
    message { "Please review this deal." }
    metadata { { source: "website" } }
  end
end
