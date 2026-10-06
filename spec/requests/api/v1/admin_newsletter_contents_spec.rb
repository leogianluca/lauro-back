require "rails_helper"
require "tempfile"

RSpec.describe "Admin newsletter contents", type: :request do
  it "attaches additional images and documents to a library item" do
    editor = create(:user, :editor)
    content = NewsletterContent.create!(title: "Investment article", content_type: "article")
    image = Tempfile.new([ "library", ".png" ])
    image.binmode
    image.write(Vips::Image.black(640, 360).write_to_buffer(".png"))
    image.close
    document = Tempfile.new([ "memo", ".pdf" ])
    document.write("%PDF-1.4\n% test")
    document.close

    post "/api/v1/admin/newsletter_contents/#{content.id}/media",
         params: {
           images: [ Rack::Test::UploadedFile.new(image.path, "image/png") ],
           documents: [ Rack::Test::UploadedFile.new(document.path, "application/pdf") ]
         },
         headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "images_count")).to eq(1)
    expect(json_response.dig("data", "documents_count")).to eq(1)
  ensure
    image&.unlink
    document&.unlink
  end

  it "rejects invalid library images without attaching them" do
    editor = create(:user, :editor)
    content = NewsletterContent.create!(title: "Invalid asset", content_type: "article")
    image = Tempfile.new([ "invalid", ".png" ])
    image.write("not-an-image")
    image.close

    post "/api/v1/admin/newsletter_contents/#{content.id}/media",
         params: { images: [ Rack::Test::UploadedFile.new(image.path, "image/png") ] },
         headers: auth_headers_for(editor)

    expect(response).to have_http_status(:unprocessable_content)
    expect(content.reload.images).not_to be_attached
  ensure
    image&.unlink
  end

  it "returns a publication checklist for an item" do
    editor = create(:user, :editor)
    content = NewsletterContent.create!(title: "Market update", content_type: "article", description: "Analysis", alt_text: "Market skyline")

    get "/api/v1/admin/newsletter_contents/#{content.id}/preview", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "publishable")).to be(true)
    expect(json_response.dig("data", "checklist", "links")).to be(true)
    expect(json_response.dig("data", "html")).to include("Market update", "Analysis")
    expect(json_response.dig("data", "desktop_html")).to include("max-width:680px")
    expect(json_response.dig("data", "mobile_html")).to include("width:375px")
  end

  it "returns CTA destination and tracking metadata" do
    editor = create(:user, :editor)
    content = NewsletterContent.create!(title: "CTA", content_type: "cta", cta_label: "See more", cta_url: "https://example.com", cta_target: "_blank", tracking_key: "home.hero")

    get "/api/v1/admin/newsletter_contents/#{content.id}", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "cta_target")).to eq("_blank")
    expect(json_response.dig("data", "tracking_key")).to eq("home.hero")
  end

  it "blocks the checklist when an event has incomplete details" do
    editor = create(:user, :editor)
    content = NewsletterContent.create!(title: "Open house", content_type: "event", description: "Visit", alt_text: "House", event_date: Date.current, event_time: "10:00", event_timezone: "America/New_York")

    get "/api/v1/admin/newsletter_contents/#{content.id}/preview", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "publishable")).to be(false)
    expect(json_response.dig("data", "checklist", "event_details")).to be(false)
  end

  it "blocks publication when the checklist is incomplete" do
    editor = create(:user, :editor)
    content = NewsletterContent.create!(title: "Article", content_type: "article")

    patch "/api/v1/admin/newsletter_contents/#{content.id}/publish", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:unprocessable_content)
    expect(content.reload).to be_draft
  end

  it "supports favoriting and filtering recently used items" do
    editor = create(:user, :editor)
    content = NewsletterContent.create!(title: "Featured item", content_type: "article")

    patch "/api/v1/admin/newsletter_contents/#{content.id}/favorite", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(content.reload).to be_favorite

    content.update!(used_count: 1, last_used_at: Time.current)
    get "/api/v1/admin/newsletter_contents?favorite=true&used=recent", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(json_response.fetch("data").map { |item| item.fetch("id") }).to include(content.id)
  end
end
