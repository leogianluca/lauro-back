require "rails_helper"

RSpec.describe "Admin market reports", type: :request do
  it "keeps reading, editing, and changing visibility on separate routes" do
    viewer = create(:user, :viewer)
    editor = create(:user, :editor)
    report = create(:market_report, visibility: :private)

    get "/api/v1/admin/market_reports/#{report.id}", headers: auth_headers_for(viewer)
    expect(response).to have_http_status(:ok)
    expect(report.reload).to be_visibility_private

    patch "/api/v1/admin/market_reports/#{report.id}",
      params: { market_report: { title: "Updated market report" } },
      headers: auth_headers_for(editor)
    expect(response).to have_http_status(:ok)
    expect(report.reload.title).to eq("Updated market report")
    expect(report).to be_visibility_private

    patch "/api/v1/admin/market_reports/#{report.id}/show", headers: auth_headers_for(viewer)
    expect(response).to have_http_status(:forbidden)
    expect(report.reload).to be_visibility_private

    patch "/api/v1/admin/market_reports/#{report.id}/show", headers: auth_headers_for(editor)
    expect(response).to have_http_status(:ok)
    expect(report.reload).to be_visibility_public
  end

  it "allows an editor to create and publish a report" do
    editor = create(:user, :editor)

    post "/api/v1/admin/market_reports",
         params: { market_report: attributes_for(:market_report, title: "June 2026 Report") },
         headers: auth_headers_for(editor)

    expect(response).to have_http_status(:created)
    report = MarketReport.find(json_response.dig("data", "id"))

    patch "/api/v1/admin/market_reports/#{report.id}/publish", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(report.reload).to be_published
  end

  it "does not publish a report with numbers but no cited source" do
    editor = create(:user, :editor)
    report = create(:market_report, source_name: nil)

    patch "/api/v1/admin/market_reports/#{report.id}/publish", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:unprocessable_content)
    expect(report.reload).to be_draft
  end

  it "does not publish an empty report" do
    editor = create(:user, :editor)
    report = create(:market_report, body: nil)

    patch "/api/v1/admin/market_reports/#{report.id}/publish", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:unprocessable_content)
    expect(report.reload).to be_draft
  end

  it "sets a publication date when an editor saves published status directly" do
    editor = create(:user, :editor)
    report = create(:market_report)

    patch "/api/v1/admin/market_reports/#{report.id}",
      params: { market_report: { status: "published" } },
      headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(report.reload).to be_published
    expect(report.published_at).to be_present
  end

  it "rejects an invalid reporting month when publishing" do
    editor = create(:user, :editor)
    report = create(:market_report, period: "2026-13")

    patch "/api/v1/admin/market_reports/#{report.id}/publish", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:unprocessable_content)
    expect(report.reload).to be_draft
  end

  it "rejects a viewer from creating a report" do
    viewer = create(:user, :viewer)

    post "/api/v1/admin/market_reports",
         params: { market_report: attributes_for(:market_report) },
         headers: auth_headers_for(viewer)

    expect(response).to have_http_status(:forbidden)
  end
end
