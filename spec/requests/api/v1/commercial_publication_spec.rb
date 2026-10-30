require "rails_helper"

RSpec.describe "Simplified commercial publication", type: :request do
  it "publishes a photographed listing with one address and no hidden editorial requirements" do
    editor = create(:user, :editor)
    card = create(:investment_card, category: "commercial", asset_type: "retail", city: nil, state: nil,
      address_line1: "120 South Powerline Rd, Deerfield Beach FL 33442", summary: nil, alt_text: nil, disclaimer: nil,
      strategy: "build_to_rent", estimated_months: nil, expert_curated: true)
    card.cover_image.attach(io: Rails.root.join("spec/fixtures/files/test-image.svg").open, filename: "cover.svg", content_type: "image/svg+xml")

    patch "/api/v1/admin/investment_cards/#{card.id}/publish", headers: auth_headers_for(editor)
    expect(response).to have_http_status(:ok)
    expect(card.reload).to be_published
    expect(card.city).to be_nil
    expect(card.state).to be_nil
  end

  it "identifies the exact remaining field when the cover has not been supplied" do
    editor = create(:user, :editor)
    card = create(:investment_card, category: "commercial", city: nil, state: nil,
      address_line1: "120 South Powerline Rd, Deerfield Beach FL 33442", summary: nil, alt_text: nil, disclaimer: nil)
    patch "/api/v1/admin/investment_cards/#{card.id}/publish", headers: auth_headers_for(editor)
    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response["errors"].map { |error| error["field"] }).to eq(["cover_image"])
    expect(card.reload).to be_draft
  end
end
