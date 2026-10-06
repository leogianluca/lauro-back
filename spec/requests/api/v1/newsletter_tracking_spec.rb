require "rails_helper"

RSpec.describe "Newsletter tracking", type: :request do
  it "records one open event per delivery and returns a transparent gif" do
    delivery = create(:newsletter_delivery)
    token = delivery.signed_id(purpose: "newsletter_open")

    get "/api/v1/newsletter_tracking/#{token}/open"
    get "/api/v1/newsletter_tracking/#{token}/open"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/gif")
    expect(delivery.newsletter_metric_events.where(event_type: "opened").count).to eq(1)
  end

  it "records a click and redirects to the signed destination" do
    delivery = create(:newsletter_delivery)
    token = Rails.application.message_verifier("newsletter-link").generate(
      { "delivery_id" => delivery.id, "url" => "https://example.com/property" },
      purpose: "newsletter_click"
    )

    get "/api/v1/newsletter_tracking/#{token}/click"

    expect(response).to have_http_status(:redirect)
    expect(response).to redirect_to("https://example.com/property")
    expect(delivery.newsletter_metric_events.where(event_type: "clicked").count).to eq(1)
  end
end
