FactoryBot.define do
  factory :investment_card do
    sequence(:title) { |number| "Investment Card #{number}" }
    sequence(:slug) { |number| "investment-card-#{number}" }
    summary { "Flexible investment card summary." }
    description { "Detailed investment card description." }
    category { "residential" }
    asset_type { "multifamily" }
    strategy { "renda recorrente" }
    city { "Orlando" }
    state { "FL" }
    country { "US" }
    status { "draft" }
    visibility { "public" }
    card_level { 1 }
    featured { false }
    expert_curated { false }
    featured_position { 1 }
    price_cents { 995_000_00 }
    price_currency { "USD" }
    investment_min_cents { 199_000_00 }
    investment_max_cents { nil }
    source_url { "https://example.com/listing" }
    external_reference { "FLOR-4PLEX-0023" }
    alt_text { "Investment property" }
    disclaimer { "Informações exclusivamente informativas; não constituem recomendação de investimento." }
    metadata { { metrics: { cap_rate_projected: "8.5%" } } }
    published_at { nil }
    discarded_at { nil }

    trait :published do
      status { "published" }
      published_at { Time.current }
      after(:build) do |card|
        card.cover_image.attach(
          io: Rails.root.join("spec/fixtures/files/test-image.svg").open,
          filename: "test-image.svg",
          content_type: "image/svg+xml"
        )
      end
    end

    trait :expert_curated do
      expert_curated { true }
      curated_by { association :user }
      source_name { "Market source" }
      verified_at { Time.current }
      expert_curated_reason { "Selected after a documented review of market fit and investment risks." }
    end
  end
end
