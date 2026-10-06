require "rails_helper"

RSpec.describe "Admin newsletter dispatch", type: :request do
  include ActiveJob::TestHelper

  before { ActionMailer::Base.deliveries.clear }

  it "queues and delivers only to subscribed readers" do
    editor = create(:user, :editor)
    edition = create(:newsletter_edition, :published, title: "May Insights")
    edition.update!(body: "Read more at https://example.com", metadata: { "subject" => "May Insights", "preheader" => "Market update" })
    edition.images.attach(
      io: Rails.root.join("spec/fixtures/files/test-image.svg").open,
      filename: "test-image.svg",
      content_type: "image/svg+xml"
    )
    subscribed = create(:newsletter_subscriber, email: "active@example.com")
    create(:newsletter_subscriber, :unsubscribed, email: "inactive@example.com")

    perform_enqueued_jobs do
      post "/api/v1/admin/newsletter_editions/#{edition.id}/dispatch", headers: auth_headers_for(editor)
    end

    expect(response).to have_http_status(:accepted)
    expect(ActionMailer::Base.deliveries.map(&:to)).to contain_exactly([ subscribed.email ])
    expect(edition.newsletter_deliveries.find_by(newsletter_subscriber: subscribed)).to be_sent
  end

  it "does not dispatch a draft" do
    editor = create(:user, :editor)
    edition = create(:newsletter_edition)

    post "/api/v1/admin/newsletter_editions/#{edition.id}/dispatch", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "does not dispatch a campaign with a frozen empty audience" do
    editor = create(:user, :editor)
    edition = create(:newsletter_edition, :published, body: "Read more at https://example.com")
    edition.images.attach(io: Rails.root.join("spec/fixtures/files/test-image.svg").open, filename: "test-image.svg", content_type: "image/svg+xml")
    edition.update!(metadata: { "subject" => "Empty", "audience_snapshot" => [] })

    post "/api/v1/admin/newsletter_editions/#{edition.id}/dispatch", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response.dig("errors", 0, "code")).to eq("empty_audience")
  end

  it "does not enqueue the same campaign twice" do
    editor = create(:user, :editor)
    edition = create(:newsletter_edition, :published, body: "Read more at https://example.com")
    edition.images.attach(io: Rails.root.join("spec/fixtures/files/test-image.svg").open, filename: "test-image.svg", content_type: "image/svg+xml")
    edition.update!(metadata: { "subject" => "Idempotent", "preheader" => "Reliable delivery", "audience_snapshot" => [ create(:newsletter_subscriber).id ] })

    expect do
      post "/api/v1/admin/newsletter_editions/#{edition.id}/dispatch", headers: auth_headers_for(editor)
    end.to have_enqueued_job(DeliverNewsletterCampaignJob).once

    post "/api/v1/admin/newsletter_editions/#{edition.id}/dispatch", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:conflict)
    expect(json_response.dig("errors", 0, "code")).to eq("already_dispatched")
  end
end
