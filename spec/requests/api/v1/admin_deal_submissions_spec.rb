require "rails_helper"

RSpec.describe "Admin deal submissions", type: :request do
  it "allows an editor to move a submission to review" do
    editor = create(:user, :editor)
    submission = create(:deal_submission)

    patch "/api/v1/admin/deal_submissions/#{submission.id}",
          params: { deal_submission: { status: "reviewing" } },
          headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(submission.reload).to be_reviewing
  end

  it "rejects an unauthenticated index" do
    get "/api/v1/admin/deal_submissions"

    expect(response).to have_http_status(:unauthorized)
  end

  it "lists attachment metadata only in the authorized detail and streams the selected file" do
    editor = create(:user, :editor)
    submission = create(:deal_submission)
    submission.images.attach(io: StringIO.new("image bytes"), filename: "front.png", content_type: "image/png")
    submission.documents.attach(io: StringIO.new("document bytes"), filename: "memo.pdf", content_type: "application/pdf")
    image = submission.images.attachments.first
    document = submission.documents.attachments.first
    headers = auth_headers_for(editor)

    get "/api/v1/admin/deal_submissions", headers: headers
    expect(response).to have_http_status(:ok)
    expect(json_response.fetch("data").first).not_to have_key("attachments")

    get "/api/v1/admin/deal_submissions/#{submission.id}", headers: headers
    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "attachments", "images", 0)).to include("id" => image.id, "filename" => "front.png")
    expect(json_response.dig("data", "attachments", "documents", 0)).to include("id" => document.id, "filename" => "memo.pdf")
    expect(json_response.dig("data", "attachments", "documents", 0)).not_to have_key("url")

    get "/api/v1/admin/deal_submissions/#{submission.id}/attachments/#{document.id}", headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("document bytes")
    expect(response.headers.fetch("Content-Disposition")).to include("attachment")
    expect(response.headers.fetch("Cache-Control")).to include("private")

    get "/api/v1/admin/deal_submissions/#{submission.id}/attachments/#{image.id}"
    expect(response).to have_http_status(:unauthorized)
    get "/api/v1/admin/deal_submissions/#{submission.id}/attachments/999999", headers: headers
    expect(response).to have_http_status(:not_found)

    other_submission = create(:deal_submission)
    other_submission.documents.attach(io: StringIO.new("private elsewhere"), filename: "other.pdf", content_type: "application/pdf")
    other_document = other_submission.documents.attachments.first
    get "/api/v1/admin/deal_submissions/#{submission.id}/attachments/#{other_document.id}", headers: headers
    expect(response).to have_http_status(:not_found)
  end
end
