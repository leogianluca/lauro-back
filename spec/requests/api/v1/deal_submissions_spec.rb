require "rails_helper"

RSpec.describe "Deal submissions", type: :request do
  it "accepts a public deal submission" do
    post "/api/v1/deal_submissions", params: {
      deal_submission: {
        submitter_name: "Broker Name",
        submitter_email: " BROKER@example.com ",
        company_name: "Brokerage LLC",
        category: "residential",
        price_cents: "1234500",
        investment_min_cents: "250000",
        message: "New property for review."
      }, consent: true
    }

    expect(response).to have_http_status(:created)
    expect(DealSubmission.last.submitter_email).to eq("broker@example.com")
    expect(DealSubmission.last).to be_new_submission
    expect(DealSubmission.last.consented_at).to be_present
    expect(DealSubmission.last.price_cents).to eq(1_234_500)
    expect(DealSubmission.last.investment_min_cents).to eq(250_000)
    expect(json_response.dig("data", "status")).to eq("new_submission")
    expect(json_response.dig("data").keys).to contain_exactly(
      "id", "status", "created_at", "images_count", "documents_count"
    )
  end

  it "accepts image and document uploads and returns only public confirmation data" do
    image = Tempfile.new([ "public-submission", ".png" ])
    image.binmode
    image.write(Vips::Image.black(640, 360).write_to_buffer(".png"))
    image.close
    document = Tempfile.new([ "offering-memo", ".pdf" ])
    document.write("%PDF-1.4\n% test")
    document.close

    post "/api/v1/deal_submissions", params: {
      deal_submission: {
        submitter_name: "Broker Name",
        submitter_email: "broker@example.com",
        company_name: "Brokerage LLC",
        title: "Test opportunity",
        category: "residential",
        city: "Orlando",
        state: "FL",
        message: "A test submission with attachments."
      },
      consent: true,
      images: [ Rack::Test::UploadedFile.new(image.path, "image/png") ],
      documents: [ Rack::Test::UploadedFile.new(document.path, "application/pdf") ]
    }

    expect(response).to have_http_status(:created)
    expect(DealSubmission.last.images).to be_attached
    expect(DealSubmission.last.documents).to be_attached
    expect(json_response.dig("data", "images_count")).to eq(1)
    expect(json_response.dig("data", "documents_count")).to eq(1)
    expect(json_response.dig("data")).not_to have_key("internal_notes")
    expect(json_response.dig("data")).not_to have_key("submitter_email")
  ensure
    image&.unlink
    document&.unlink
  end

  it "rejects a public deal submission without consent" do
    post "/api/v1/deal_submissions", params: {
      deal_submission: { submitter_name: "Broker Name", submitter_email: "broker@example.com" }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response.dig("errors", 0, "code")).to eq("consent_required")
  end

  it "returns a field-addressable error for an invalid submitter email without creating a submission" do
    post "/api/v1/deal_submissions", params: {
      deal_submission: { submitter_name: "QA Submitter", submitter_email: "invalid-email" },
      consent: true
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response.dig("errors", 0)).to include(
      "code" => "validation_error",
      "field" => "submitter_email"
    )
    expect(DealSubmission.count).to eq(0)
  end

  it "returns a field error when a submitted image has an incompatible extension" do
    image = Tempfile.new([ "not-an-image", ".txt" ])
    image.write("not an image")
    image.close

    post "/api/v1/deal_submissions", params: {
      deal_submission: {
        submitter_name: "Broker Name",
        submitter_email: "broker@example.com"
      },
      consent: true,
      images: [ Rack::Test::UploadedFile.new(image.path, "image/png") ]
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response.dig("errors", 0, "field")).to eq("images")
    expect(DealSubmission.count).to eq(0)
  ensure
    image&.unlink
  end

  it "rejects documents whose declared type and extension do not match" do
    document = Tempfile.new([ "not-a-pdf", ".txt" ])
    document.write("not a PDF")
    document.close

    post "/api/v1/deal_submissions", params: {
      deal_submission: {
        submitter_name: "Broker Name",
        submitter_email: "broker@example.com"
      },
      consent: true,
      documents: [ Rack::Test::UploadedFile.new(document.path, "application/pdf") ]
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(json_response.dig("errors", 0, "field")).to eq("documents")
    expect(DealSubmission.count).to eq(0)
  ensure
    document&.unlink
  end

  it "rejects more than 10 images or documents before creating a submission" do
    %w[images documents].each do |field|
      post "/api/v1/deal_submissions", params: {
        deal_submission: {
          submitter_name: "Broker Name",
          submitter_email: "broker@example.com"
        },
        consent: true,
        field => Array.new(11) { "excess attachment" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig("errors", 0, "code")).to eq("too_many_files")
      expect(json_response.dig("errors", 0, "field")).to eq(field)
    end

    expect(DealSubmission.count).to eq(0)
  end

  it "rejects invalid or out-of-range cent amounts before creating a submission" do
    [
      [ "price_cents", "12.5" ],
      [ "price_cents", "-1" ],
      [ "investment_min_cents", "2147483648" ]
    ].each do |field, amount|
      post "/api/v1/deal_submissions", params: {
        deal_submission: {
          submitter_name: "Broker Name",
          submitter_email: "broker@example.com",
          field => amount
        },
        consent: true
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig("errors", 0, "code")).to eq("invalid_amount")
      expect(json_response.dig("errors", 0, "field")).to eq("deal_submission.#{field}")
    end

    expect(DealSubmission.count).to eq(0)
  end
end
