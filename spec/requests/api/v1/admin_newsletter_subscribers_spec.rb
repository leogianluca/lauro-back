require "rails_helper"

RSpec.describe "Admin newsletter subscribers", type: :request do
  it "allows an editor to list subscribers" do
    editor = create(:user, :editor)
    create(:newsletter_subscriber)

    get "/api/v1/admin/newsletter_subscribers", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("meta", "count")).to eq(1)
  end

  it "allows an editor to unsubscribe an address" do
    editor = create(:user, :editor)
    subscriber = create(:newsletter_subscriber)

    patch "/api/v1/admin/newsletter_subscribers/#{subscriber.id}",
          params: { status: "unsubscribed" },
          headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(subscriber.reload).to be_unsubscribed
  end

  it "allows only an admin to export and anonymize subscriber data" do
    admin = create(:user, :admin)
    subscriber = create(:newsletter_subscriber, email: "private@example.com", source: "landing-page")

    get "/api/v1/admin/newsletter_subscribers/export", headers: auth_headers_for(admin)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("private@example.com")

    delete "/api/v1/admin/newsletter_subscribers/#{subscriber.id}", headers: auth_headers_for(admin)
    expect(response).to have_http_status(:ok)
    expect(subscriber.reload.email).to end_with("@invalid.local")
    expect(subscriber.reload.metadata).to eq({})
  end

  it "does not allow an editor to export or anonymize subscribers" do
    editor = create(:user, :editor)
    subscriber = create(:newsletter_subscriber)

    get "/api/v1/admin/newsletter_subscribers/export", headers: auth_headers_for(editor)
    expect(response).to have_http_status(:forbidden)

    delete "/api/v1/admin/newsletter_subscribers/#{subscriber.id}", headers: auth_headers_for(editor)
    expect(response).to have_http_status(:forbidden)
  end
end
