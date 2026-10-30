require "rails_helper"

RSpec.describe "Financing simulation API contract", type: :request do
  it "stores typed defaults and returns only public simulation inputs" do
    editor = create(:user, :editor)
    post "/api/v1/admin/investment_cards",
      params: { investment_card: attributes_for(:investment_card, category: "commercial", price_cents: 900_000_000,
        financing_available: true, financing: { type: "bank_financing", down_payment_cents: "450000000", interest_rate_percent: "8.125", term_years: "30", internal_note: "private" }) },
      headers: auth_headers_for(editor), as: :json
    expect(response).to have_http_status(:created)
    card = InvestmentCard.find(json_response.dig("data", "id"))
    expect(card.financing).to include("down_payment_cents" => 450_000_000, "interest_rate_percent" => 8.125, "term_years" => 30)
    card.cover_image.attach(io: Rails.root.join("spec/fixtures/files/test-image.svg").open, filename: "cover.svg", content_type: "image/svg+xml")
    card.publish!
    get "/api/v1/investment_cards/#{card.slug}"
    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "financing")).to eq("type" => "bank_financing", "down_payment_cents" => 450_000_000, "interest_rate_percent" => 8.125, "term_years" => 30)

    patch "/api/v1/admin/investment_cards/#{card.id}", params: { investment_card: { financing: { interest_rate_percent: false } } }, headers: auth_headers_for(editor), as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(card.reload.financing["interest_rate_percent"]).to eq(8.125)
  end
end
