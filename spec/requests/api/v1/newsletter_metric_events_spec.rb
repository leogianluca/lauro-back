require "rails_helper"

RSpec.describe "Newsletter metric events", type: :request do
  it "rejects provider events from the public tracking endpoint" do
    edition = create(:newsletter_edition, :published)

    post "/api/v1/newsletter_metric_events", params: {
      event: {
        newsletter_edition_id: edition.id,
        event_type: "spam_complaint",
        recipient_email: "reader@example.com",
        idempotency_key: "complaint-1"
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(edition.newsletter_metric_events).to be_empty
  end
end
