require "rails_helper"

RSpec.describe NewsletterCampaigns::HtmlRenderer, type: :service do
  it "renders composed blocks and sanitizes unsafe markup" do
    edition = create(:newsletter_edition, body: "<p>Corpo <strong>rico</strong></p>", metadata: {
      "blocks" => [ { "title" => "Destaque", "content" => "<p>Leia <a href='https://example.com'>aqui</a></p><script>alert(1)</script>" } ],
      "content_snapshots" => [ { "title" => "Item", "description" => "Descrição" } ]
    })

    html = described_class.new(edition).call

    expect(html).to include("Destaque", "https://example.com", "Item")
    expect(html).not_to include("<script", "</script>")
  end

  it "renders safe library images and links from campaign snapshots" do
    edition = create(:newsletter_edition, metadata: {
      "content_snapshots" => [
        { "title" => "Imóvel em destaque", "description" => "Vista para o mar", "image_url" => "https://cdn.example.com/home.jpg", "alt_text" => "Casa na praia", "cta_url" => "https://example.com/details", "cta_label" => "Ver detalhes" }
      ]
    })

    html = described_class.new(edition).call

    expect(html).to include("https://cdn.example.com/home.jpg", "Casa na praia", "Ver detalhes")
    expect(html).not_to include("javascript:")
  end
end
