require "rails_helper"

RSpec.describe "Newsletter subscribers", type: :request do
  it "subscribes and normalizes an email" do
    post "/api/v1/newsletter_subscribers", params: {
      subscriber: { email: "  Investor@Example.com ", source: "homepage" }, consent: true
    }

    expect(response).to have_http_status(:created)
    expect(NewsletterSubscriber.last.email).to eq("investor@example.com")
    expect(NewsletterSubscriber.last).to be_subscribed
    expect(NewsletterSubscriber.last.consented_at).to be_present
    expect(json_response.dig("data", "unsubscribe_token")).to be_present
  end

  it "reactivates an unsubscribed email without creating a duplicate" do
    subscriber = create(:newsletter_subscriber, :unsubscribed, email: "investor@example.com")

    post "/api/v1/newsletter_subscribers", params: {
      subscriber: { email: "INVESTOR@example.com" }, consent: true
    }

    expect(response).to have_http_status(:created)
    expect(NewsletterSubscriber.count).to eq(1)
    expect(subscriber.reload).to be_subscribed
    expect(subscriber.consented_at).to be_present
  end

  it "treats a repeated subscription as idempotent" do
    subscriber = create(:newsletter_subscriber, email: "investor@example.com")

    post "/api/v1/newsletter_subscribers", params: {
      subscriber: { email: "INVESTOR@example.com" }, consent: true
    }

    expect(response).to have_http_status(:created)
    expect(NewsletterSubscriber.count).to eq(1)
    expect(subscriber.reload).to be_subscribed
    expect(subscriber.consented_at).to be_present
  end

  it "returns a field-specific error for an invalid email" do
    post "/api/v1/newsletter_subscribers", params: {
      subscriber: { email: "not-an-email" }, consent: true
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response.dig("errors", 0, "field")).to eq("email")
    expect(NewsletterSubscriber.count).to eq(0)
  end

  it "allows unsubscribe with the signed token" do
    subscriber = create(:newsletter_subscriber, email: "investor@example.com")
    token = subscriber.signed_id(purpose: "newsletter_unsubscribe")

    delete "/api/v1/newsletter_subscribers/#{token}"

    expect(response).to have_http_status(:ok)
    expect(subscriber.reload).to be_unsubscribed
  end

  it "rejects a subscription without consent" do
    post "/api/v1/newsletter_subscribers", params: { subscriber: { email: "investor@example.com" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response.dig("errors", 0, "code")).to eq("consent_required")
    expect(NewsletterSubscriber.count).to eq(0)
  end
end
