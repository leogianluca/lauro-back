require "rails_helper"

RSpec.describe "Site settings", type: :request do
  it "returns only public values" do
    create(:site_setting, key: "public.contact", value: { whatsapp: "+1 407" }, public: true)
    create(:site_setting, key: "internal.smtp", value: { host: "private" }, public: false)

    get "/api/v1/site_settings"

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "public.contact", "whatsapp")).to eq("+1 407")
    expect(json_response.dig("data", "internal.smtp")).to be_nil
  end
end
