FactoryBot.define do
  factory :content_page do
    sequence(:title) { |number| "Institutional Page #{number}" }
    sequence(:slug) { |number| "institutional-page-#{number}" }
    page_type { "institutional" }
    eyebrow { "About Florida Investments" }
    excerpt { "A public institutional page." }
    body { "Institutional content." }
    metadata { { sections: [] } }

    trait :published do
      status { "published" }
      published_at { Time.current }
    end
  end
end
