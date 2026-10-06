FactoryBot.define do
  factory :market_report do
    sequence(:title) { |number| "Market Report #{number}" }
    sequence(:slug) { |number| "market-report-#{number}" }
    period { "2026-05" }
    excerpt { "Monthly Florida market indicators." }
    body { "Detailed report content." }
    metrics { { cap_rate_average: "6.4%" } }
    source_name { "Market source" }

    trait :published do
      status { "published" }
      published_at { Time.current }
    end
  end
end
