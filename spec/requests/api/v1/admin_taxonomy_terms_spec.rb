require "rails_helper"

RSpec.describe "Admin taxonomy terms", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { auth_headers_for(admin) }

  it "creates, updates and archives a term without showing it in the active list" do
    post "/api/v1/admin/taxonomy_terms",
         params: { taxonomy_term: { kind: "asset_type", name: "E2E Asset", slug: "e2e-asset", active: true } },
         headers: headers

    expect(response).to have_http_status(:created)
    id = response.parsed_body.dig("data", "id")

    patch "/api/v1/admin/taxonomy_terms/#{id}",
          params: { taxonomy_term: { name: "E2E Asset Updated" } },
          headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "name")).to eq("E2E Asset Updated")

    delete "/api/v1/admin/taxonomy_terms/#{id}", headers: headers
    expect(response).to have_http_status(:ok)

    get "/api/v1/admin/taxonomy_terms", headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").map { |item| item.fetch("id") }).not_to include(id)
  end

  it "rejects invalid terms without creating a record" do
    post "/api/v1/admin/taxonomy_terms",
         params: { taxonomy_term: { kind: "unknown", name: "Invalid", slug: "invalid" } },
         headers: headers

    expect(response).to have_http_status(:unprocessable_content)
    expect(TaxonomyTerm.where(slug: "invalid")).to be_empty
  end
end
