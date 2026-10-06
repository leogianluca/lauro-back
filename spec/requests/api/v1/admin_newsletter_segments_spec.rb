require "rails_helper"

RSpec.describe "Admin newsletter segments", type: :request do
  it "duplicates a segment with independent rules" do
    editor = create(:user, :editor)
    segment = NewsletterSegment.create!(
      name: "Miami",
      conditions: [ { "field" => "city", "operator" => "equals", "value" => "Miami" } ],
      contacts_count: 4
    )

    post "/api/v1/admin/newsletter_segments/#{segment.id}/duplicate", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:created)
    copy = NewsletterSegment.find(json_response.dig("data", "id"))
    expect(copy.name).to eq("Miami (cópia)")
    expect(copy.conditions).to eq(segment.conditions)
    expect(copy.contacts_count).to eq(0)
  end
end
