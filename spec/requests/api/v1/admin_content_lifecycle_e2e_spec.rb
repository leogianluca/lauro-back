require "rails_helper"
require "tempfile"

RSpec.describe "Admin content lifecycle through the public API", type: :request do
  def public_ids(path)
    get path
    expect(response).to have_http_status(:ok)
    json_response.fetch("data").map { |item| item.fetch("id") }
  end

  it "creates, edits, publishes and removes an opportunity without leaving it public" do
    admin = create(:user, :admin)
    headers = auth_headers_for(admin)

    post "/api/v1/admin/investment_cards",
      params: { investment_card: attributes_for(:investment_card, title: "Lifecycle opportunity") },
      headers: headers
    expect(response).to have_http_status(:created)
    card_id = json_response.dig("data", "id")
    card = InvestmentCard.find(card_id)
    expect(public_ids("/api/v1/investment_cards?category=residential")).not_to include(card_id)

    patch "/api/v1/admin/investment_cards/#{card_id}",
      params: { investment_card: { title: "Updated lifecycle opportunity" } },
      headers: headers
    expect(response).to have_http_status(:ok)
    expect(card.reload.title).to eq("Updated lifecycle opportunity")

    image = Tempfile.new([ "lifecycle-cover", ".png" ])
    image.binmode
    image.write(Vips::Image.black(640, 360).write_to_buffer(".png"))
    image.close
    post "/api/v1/admin/investment_cards/#{card_id}/media",
      params: { cover_image: Rack::Test::UploadedFile.new(image.path, "image/png") },
      headers: headers
    expect(response).to have_http_status(:ok)

    patch "/api/v1/admin/investment_cards/#{card_id}/publish", headers: headers
    expect(response).to have_http_status(:ok)
    expect(public_ids("/api/v1/investment_cards?category=residential")).to include(card_id)

    get "/api/v1/investment_cards/#{card.reload.slug}"
    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "title")).to eq("Updated lifecycle opportunity")

    delete "/api/v1/admin/investment_cards/#{card_id}", headers: headers
    expect(response).to have_http_status(:ok)
    expect(card.reload).to be_discarded
    expect(public_ids("/api/v1/investment_cards?category=residential")).not_to include(card_id)
    get "/api/v1/investment_cards/#{card.slug}"
    expect(response).to have_http_status(:not_found)
    get "/api/v1/admin/investment_cards/#{card_id}", headers: headers
    expect(response).to have_http_status(:not_found)
  ensure
    image&.unlink
  end

  it "creates, publishes and removes a newsletter edition" do
    admin = create(:user, :admin)
    headers = auth_headers_for(admin)
    post "/api/v1/admin/newsletter_editions",
      params: { newsletter_edition: attributes_for(:newsletter_edition, title: "Lifecycle edition") },
      headers: headers
    expect(response).to have_http_status(:created)
    edition_id = json_response.dig("data", "id")
    edition = NewsletterEdition.find(edition_id)
    expect(public_ids("/api/v1/newsletter_editions")).not_to include(edition_id)

    patch "/api/v1/admin/newsletter_editions/#{edition_id}/publish", headers: headers
    expect(response).to have_http_status(:ok)
    expect(public_ids("/api/v1/newsletter_editions")).to include(edition_id)
    get "/api/v1/newsletter_editions/#{edition.slug}"
    expect(response).to have_http_status(:ok)

    delete "/api/v1/admin/newsletter_editions/#{edition_id}", headers: headers
    expect(response).to have_http_status(:ok)
    expect(edition.reload).to be_discarded
    expect(public_ids("/api/v1/newsletter_editions")).not_to include(edition_id)
    get "/api/v1/newsletter_editions/#{edition.slug}"
    expect(response).to have_http_status(:not_found)
  end

  it "creates, publishes and removes a sourced market report" do
    admin = create(:user, :admin)
    headers = auth_headers_for(admin)
    post "/api/v1/admin/market_reports",
      params: { market_report: attributes_for(:market_report, title: "Lifecycle report") },
      headers: headers
    expect(response).to have_http_status(:created)
    report_id = json_response.dig("data", "id")
    report = MarketReport.find(report_id)
    expect(public_ids("/api/v1/market_reports")).not_to include(report_id)

    patch "/api/v1/admin/market_reports/#{report_id}/publish", headers: headers
    expect(response).to have_http_status(:ok)
    expect(public_ids("/api/v1/market_reports")).to include(report_id)
    get "/api/v1/market_reports/#{report.slug}"
    expect(response).to have_http_status(:ok)

    delete "/api/v1/admin/market_reports/#{report_id}", headers: headers
    expect(response).to have_http_status(:ok)
    expect(report.reload).to be_discarded
    expect(public_ids("/api/v1/market_reports")).not_to include(report_id)
    get "/api/v1/market_reports/#{report.slug}"
    expect(response).to have_http_status(:not_found)
  end
end
