require "rails_helper"

RSpec.describe "Admin dashboard", type: :request do
  it "returns aggregated metrics for a read-only viewer" do
    viewer = create(:user, :viewer)
    create(:investment_card, :published)
    create(:lead)
    create(:newsletter_subscriber)

    get "/api/v1/admin/dashboard", headers: auth_headers_for(viewer)

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "investment_cards", "published")).to eq(1)
    expect(json_response.dig("data", "leads", "new")).to eq(1)
    expect(json_response.dig("data", "newsletter", "subscribed")).to eq(1)
  end

  it "requires authentication" do
    get "/api/v1/admin/dashboard"

    expect(response).to have_http_status(:unauthorized)
  end
end
