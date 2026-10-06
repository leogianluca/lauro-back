require "rails_helper"

RSpec.describe "Content pages", type: :request do
  it "lists published institutional pages" do
    page = create(:content_page, :published, title: "Our Methodology")
    create(:content_page, title: "Draft Methodology")

    get "/api/v1/content_pages"

    expect(response).to have_http_status(:ok)
    expect(json_response["data"].map { |item| item["id"] }).to eq([ page.id ])
  end

  it "returns the full page by slug" do
    page = create(:content_page, :published, slug: "our-methodology")

    get "/api/v1/content_pages/our-methodology"

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "body")).to eq("Institutional content.")
  end

  it "returns the standard not-found envelope for a missing public page" do
    get "/api/v1/content_pages/missing-page"

    expect(response).to have_http_status(:not_found)
    expect(json_response.dig("errors", 0, "code")).to eq("not_found")
    expect(json_response["data"]).to be_nil
  end

  it "requires complete translated text in every public content block" do
    page = create(
      :content_page,
      :published,
      slug: "translated-methodology",
      title: "Metodologia",
      eyebrow: "Institucional",
      excerpt: "Nossa abordagem",
      body: "Conteúdo completo",
      content_blocks: [ { "type" => "cta", "title" => "Fale conosco", "content" => "Agende uma conversa", "button_label" => "Contato", "button_url" => "/contact" } ]
    )
    page.update!(metadata: page.metadata.to_h.merge(
      "translations" => {
        "en" => {
          "status" => "published", "complete" => true,
          "fields" => {
            "title" => "Methodology", "eyebrow" => "Institutional", "excerpt" => "Our approach", "body" => "Complete content",
            "content_blocks" => [ { "type" => "cta", "title" => "Contact us", "content" => "Schedule a conversation", "button_label" => "Contact" } ]
          }
        }
      }
    ))

    get "/api/v1/content_pages/translated-methodology?locale=en"

    expect(json_response.dig("data", "title")).to eq("Methodology")
    expect(json_response.dig("data", "content_blocks", 0, "button_url")).to eq("/contact")
    expect(json_response.dig("data", "locale", "fallback_used")).to be(false)
  end
end
