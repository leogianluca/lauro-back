require "rails_helper"

RSpec.describe "Newsletter editions", type: :request do
  it "returns only public published editions" do
    edition = create(:newsletter_edition, :published, title: "May Market Report")
    create(:newsletter_edition, title: "Draft")
    create(:newsletter_edition, :published, visibility: "private", title: "Private")

    get "/api/v1/newsletter_editions"

    expect(response).to have_http_status(:ok)
    expect(json_response["data"].map { |item| item["id"] }).to eq([ edition.id ])
  end

  it "returns a published edition by slug" do
    edition = create(:newsletter_edition, :published, slug: "may-market-report")

    get "/api/v1/newsletter_editions/may-market-report"

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "id")).to eq(edition.id)
    expect(json_response.dig("data", "body")).to eq("Newsletter content.")
  end

  it "returns the standard not-found envelope for a missing public edition" do
    get "/api/v1/newsletter_editions/missing-edition"

    expect(response).to have_http_status(:not_found)
    expect(json_response.dig("errors", 0, "code")).to eq("not_found")
    expect(json_response["data"]).to be_nil
  end

  it "uses an explicitly published, complete edition translation" do
    edition = create(:newsletter_edition, :published, slug: "localized-edition", title: "Edição", excerpt: "Resumo", body: "Conteúdo", cta_label: "Ver oportunidades")
    edition.update!(metadata: edition.metadata.to_h.merge(
      "translations" => {
        "es" => { "status" => "published", "complete" => true, "fields" => { "title" => "Edición", "excerpt" => "Resumen", "body" => "Contenido", "cta_label" => "Ver oportunidades" } }
      }
    ))

    get "/api/v1/newsletter_editions/localized-edition?locale=es"

    expect(json_response.dig("data", "title")).to eq("Edición")
    expect(json_response.dig("data", "cta_label")).to eq("Ver oportunidades")
    expect(json_response.dig("data", "locale", "fallback_used")).to be(false)
  end
end
