require "rails_helper"

RSpec.describe "Admin leads", type: :request do
  it "allows an editor to update a lead status" do
    editor = create(:user, :editor)
    lead = create(:lead)

    patch "/api/v1/admin/leads/#{lead.id}",
          params: { lead: { status: "contacted" } },
          headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(lead.reload).to be_contacted
  end

  it "rejects an unauthenticated lead index" do
    get "/api/v1/admin/leads"

    expect(response).to have_http_status(:unauthorized)
  end
end
