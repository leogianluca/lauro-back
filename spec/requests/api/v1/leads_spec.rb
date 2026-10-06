require "rails_helper"

RSpec.describe "Leads", type: :request do
  it "accepts a public contact request" do
    post "/api/v1/leads", params: {
      lead: {
        name: "Maria Silva",
        email: "maria@example.com",
        phone: "+1 (407) 555-0100",
        source: "investment_card",
        message: "I want to understand this property.",
        consented_at: 10.years.ago
      },
      consent: true
    }

    expect(response).to have_http_status(:created)
    expect(json_response.dig("data", "status")).to eq("new_lead")
    expect(json_response.dig("data").keys).to contain_exactly("id", "status", "created_at")
    expect(json_response.dig("data")).not_to have_key("email")
    expect(json_response.dig("data")).not_to have_key("internal_notes")
    expect(Lead.last).to be_new_lead
    expect(Lead.last.phone).to eq("+1 (407) 555-0100")
    expect(Lead.last.consented_at).to be_within(5.seconds).of(Time.current)
  end

  it "associates a contact request only with a published public investment card" do
    card = create(:investment_card, :published)

    post "/api/v1/leads", params: {
      lead: {
        name: "Maria Silva",
        email: "maria@example.com",
        investment_card_id: card.id
      },
      consent: true
    }

    expect(response).to have_http_status(:created)
    expect(Lead.last.investment_card_id).to eq(card.id)
  end

  it "does not create a contact request for a hidden or unpublished investment card" do
    card = create(:investment_card)

    post "/api/v1/leads", params: {
      lead: {
        name: "Maria Silva",
        email: "maria@example.com",
        investment_card_id: card.id
      },
      consent: true
    }

    expect(response).to have_http_status(:not_found)
    expect(json_response.dig("errors", 0, "code")).to eq("not_found")
    expect(Lead.count).to eq(0)
  end

  it "rejects a public contact request without consent" do
    post "/api/v1/leads", params: { lead: { name: "Maria Silva", email: "maria@example.com" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response.dig("errors", 0, "code")).to eq("consent_required")
  end

  it "returns a field-addressable error for an invalid contact email without creating a lead" do
    post "/api/v1/leads", params: {
      lead: { name: "QA Contact", email: "invalid-email" },
      consent: true
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response.dig("errors", 0)).to include(
      "code" => "validation_error",
      "field" => "email"
    )
    expect(Lead.count).to eq(0)
  end

  it "returns a field-addressable error for an invalid optional phone without creating a lead" do
    post "/api/v1/leads", params: {
      lead: { name: "QA Contact", email: "maria@example.com", phone: "call me" },
      consent: true
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response.dig("errors", 0)).to include(
      "code" => "validation_error",
      "field" => "phone"
    )
    expect(Lead.count).to eq(0)
  end
end
