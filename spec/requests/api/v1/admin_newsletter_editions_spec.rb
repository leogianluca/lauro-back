require "rails_helper"

RSpec.describe "Admin newsletter editions", type: :request do
  it "does not let a viewer make a private edition public while reading it" do
    viewer = create(:user, :viewer)
    editor = create(:user, :editor)
    edition = create(:newsletter_edition, visibility: :private)

    get "/api/v1/admin/newsletter_editions/#{edition.id}", headers: auth_headers_for(viewer)
    expect(response).to have_http_status(:ok)
    expect(edition.reload).to be_visibility_private

    patch "/api/v1/admin/newsletter_editions/#{edition.id}/show", headers: auth_headers_for(viewer)
    expect(response).to have_http_status(:forbidden)
    expect(edition.reload).to be_visibility_private

    patch "/api/v1/admin/newsletter_editions/#{edition.id}/show", headers: auth_headers_for(editor)
    expect(response).to have_http_status(:ok)
    expect(edition.reload).to be_visibility_public
  end

  it "allows an editor to create and publish an edition" do
    editor = create(:user, :editor)

    post "/api/v1/admin/newsletter_editions",
         params: { newsletter_edition: attributes_for(:newsletter_edition, title: "June Insights") },
         headers: auth_headers_for(editor)

    expect(response).to have_http_status(:created)
    edition = NewsletterEdition.find(json_response.dig("data", "id"))

    patch "/api/v1/admin/newsletter_editions/#{edition.id}/publish", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(edition.reload).to be_published
  end

  it "keeps an empty edition as a draft when an editor attempts publication" do
    editor = create(:user, :editor)
    edition = create(:newsletter_edition, body: nil)

    patch "/api/v1/admin/newsletter_editions/#{edition.id}/publish", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:unprocessable_content)
    expect(edition.reload).to be_draft
  end

  it "sets a publication date when an editor saves published status directly" do
    editor = create(:user, :editor)
    edition = create(:newsletter_edition)

    patch "/api/v1/admin/newsletter_editions/#{edition.id}",
      params: { newsletter_edition: { status: "published" } },
      headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(edition.reload).to be_published
    expect(edition.published_at).to be_present
  end

  it "does not allow a viewer to create an edition" do
    viewer = create(:user, :viewer)

    post "/api/v1/admin/newsletter_editions",
         params: { newsletter_edition: attributes_for(:newsletter_edition) },
         headers: auth_headers_for(viewer)

    expect(response).to have_http_status(:forbidden)
  end

  it "returns rendered html for the review preview" do
    editor = create(:user, :editor)
    edition = create(:newsletter_edition, body: "<p>Market update</p>", metadata: { "blocks" => [ { "type" => "text", "title" => "Highlights", "content" => "Demand is strong." } ] })

    get "/api/v1/admin/newsletter_editions/#{edition.id}/preview", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "html")).to include("Market Insight", "Market update", "Highlights", "Descadastrar-se")
    expect(json_response.dig("data", "desktop_html")).to include("max-width:680px")
    expect(json_response.dig("data", "mobile_html")).to include("width:375px")
  end
end
