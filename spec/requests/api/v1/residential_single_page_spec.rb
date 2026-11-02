require "rails_helper"

RSpec.describe "Single-page residential registration", type: :request do
  [
    { asset_type: "single_family", strategy: "renda_recorrente", living_area_sqft: 2200, bedrooms: 4, bathrooms: 2, year_built: 2006 },
    { asset_type: "land", strategy: "buy_and_hold", property_details: { total_acreage: "2.5" } },
    { asset_type: "condo", strategy: "build_to_rent", living_area_sqft: 1800, bedrooms: 2, bathrooms: 2, estimated_months: 18 }
  ].each do |variant|
    it "saves and publishes #{variant[:asset_type]} with the simplified payload and a cover" do
      editor = create(:user, :editor)
      title = "Residential listing at 123 Pine Street"
      attributes = {
        title: title, slug: "single-page-#{variant[:asset_type]}", category: "residential", city: "Orlando", state: "FL", country: "US",
        address_line1: "123 Pine Street", status: "draft", visibility: "public", card_level: 2, market_status: "active",
        description: "Single-page listing description.", summary: "Single-page listing description.", alt_text: title,
        disclaimer: "For informational purposes only. Past or projected returns do not guarantee future results. Consult your advisors before making a decision.",
        price_cents: 72_845_050, down_payment_cents: 14_569_010, down_payment_percent: 20
      }.merge(variant)
      post "/api/v1/admin/investment_cards", params: { investment_card: attributes }, headers: auth_headers_for(editor)
      expect(response).to have_http_status(:created)
      card = InvestmentCard.find(json_response.dig("data", "id"))
      card.cover_image.attach(io: Rails.root.join("spec/fixtures/files/test-image.svg").open, filename: "cover.svg", content_type: "image/svg+xml")

      patch "/api/v1/admin/investment_cards/#{card.id}/publish", headers: auth_headers_for(editor)
      expect(response).to have_http_status(:ok)
      expect(card.reload).to be_published
      expect(card.price_cents).to eq(72_845_050)
      expect(card.down_payment_cents).to eq(14_569_010)
      expect(card.asset_type).to eq(variant[:asset_type])
    end
  end
end
