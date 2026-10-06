FactoryBot.define do
  factory :investment_company do
    sequence(:name) { |number| "Investment Company #{number}" }
    sector { "Real Estate" }
    website { "https://example.com" }
  end
end
