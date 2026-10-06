FactoryBot.define do
  factory :newsletter_edition do
    sequence(:title) { |number| "Market Insight #{number}" }
    sequence(:slug) { |number| "market-insight-#{number}" }
    excerpt { "A concise market update for investors." }
    body { "Newsletter content." }
    status { "draft" }
    visibility { "public" }
    metadata { { topics: [ "market" ] } }

    trait :published do
      status { "published" }
      published_at { Time.current }
    end
  end
end
