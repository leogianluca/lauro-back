require "rails_helper"

RSpec.describe "Business publication from the final input table", type: :request do
  let(:editor) { create(:user, :editor) }

  def photographed_business(attributes = {})
    card = create(:investment_card, {
      category: "business", card_level: 2, region: "Orange County", city: nil, state: nil,
      sector: nil, summary: nil, alt_text: nil, disclaimer: nil, owner_involvement: "part_time",
      franchise: false, description: "A local restaurant business.",
      business_details: { "business_type" => "Restaurant", "cash_flow_cents" => 0, "visa_program" => "E-2" }
    }.merge(attributes))
    card.cover_image.attach(io: Rails.root.join("spec/fixtures/files/test-image.svg").open, filename: "cover.svg", content_type: "image/svg+xml")
    card
  end

  it "publishes the table inputs without the removed sector, subtype and SDE requirements" do
    card = photographed_business
    patch "/api/v1/admin/investment_cards/#{card.id}/publish", headers: auth_headers_for(editor)
    expect(response).to have_http_status(:ok)
    expect(card.reload).to be_published
    expect(card.franchise).to be(false)
    get "/api/v1/investment_cards", params: { category: "business" }
    payload = json_response.fetch("data").find { |item| item["id"] == card.id }
    expect(payload.fetch("business_details")).to include("business_type" => "Restaurant", "cash_flow_cents" => 0, "visa_program" => "E-2")
    expect(payload.fetch("description")).to eq("A local restaurant business.")
  end

  it "accepts integer cents, rejects formatted money and preserves the last saved amount" do
    card = photographed_business
    patch "/api/v1/admin/investment_cards/#{card.id}", headers: auth_headers_for(editor), params: {
      investment_card: { business_details: { business_type: "Restaurant", cash_flow_cents: "7500000" } }
    }
    expect(response).to have_http_status(:ok)
    expect(card.reload.business_details["cash_flow_cents"]).to eq(7_500_000)
    [ "75,000.00", -1, 75.5, "9007199254740992" ].each do |invalid|
      patch "/api/v1/admin/investment_cards/#{card.id}", headers: auth_headers_for(editor), params: {
        investment_card: { business_details: { business_type: "Restaurant", cash_flow_cents: invalid } }
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(card.reload.business_details["cash_flow_cents"]).to eq(7_500_000)
    end
  end

  it "keeps legacy data publishable without reclassifying SDE as cash flow" do
    card = photographed_business(sector: "Comércio", business_details: { "segment" => "Retail", "sde_annual_cents" => 5_000_000 })
    patch "/api/v1/admin/investment_cards/#{card.id}/publish", headers: auth_headers_for(editor)
    expect(response).to have_http_status(:ok)
    expect(card.reload.business_details).not_to have_key("cash_flow_cents")
    expect(card.business_details["sde_annual_cents"]).to eq(5_000_000)
  end
end
