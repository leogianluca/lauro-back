FactoryBot.define do
  factory :media_import_batch do
    investment_card
    total_items { 0 }
  end

  factory :media_import_item do
    media_import_batch
    kind { "gallery_image" }
    position { 1 }
  end
end
