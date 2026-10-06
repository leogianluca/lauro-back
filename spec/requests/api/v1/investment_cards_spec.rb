require "rails_helper"

RSpec.describe "Investment cards", type: :request do
  describe "GET /api/v1/investment_cards" do
    it "returns only published cards" do
      published = create(:investment_card, :published, title: "Published Card")
      create(:investment_card, title: "Draft Card")

      get "/api/v1/investment_cards"

      expect(response).to have_http_status(:ok)
      expect(json_response["data"].size).to eq(1)
      expect(json_response.dig("data", 0, "id")).to eq(published.id)
      expect(json_response.dig("meta", "count")).to eq(1)
    end

    it "includes supplied residential yield indicators without inventing missing values" do
      create(:investment_card, :published, gross_yield_percent: 8.7,
        hpi_10_year_percent: 42.5)

      get "/api/v1/investment_cards"

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("data", 0, "gross_yield_percent").to_f).to eq(8.7)
      expect(json_response.dig("data", 0, "hpi_10_year_percent").to_f).to eq(42.5)
    end

    it "filters public cards by category, curation and price" do
      matching = create(:investment_card, :published, :expert_curated, category: "commercial", price_cents: 500_000_00)
      create(:investment_card, :published, :expert_curated, category: "residential", price_cents: 500_000_00)
      create(:investment_card, :published, category: "commercial", expert_curated: false, price_cents: 900_000_00)

      get "/api/v1/investment_cards", params: {
        category: "commercial",
        expert_curated: "true",
        max_price_cents: 600_000_00
      }

      expect(response).to have_http_status(:ok)
      expect(json_response["data"].map { |card| card["id"] }).to eq([ matching.id ])
    end

    it "filters public opportunities to the manually featured cards in a category" do
      featured = create(:investment_card, :published, featured: true, category: "residential")
      create(:investment_card, :published, featured: false, category: "residential")
      create(:investment_card, :published, featured: true, category: "commercial")

      get "/api/v1/investment_cards", params: { category: "residential", featured: "true" }

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("data").map { |card| card.fetch("id") }).to eq([ featured.id ])
    end

    it "matches a partial city name without depending on case" do
      matching = create(:investment_card, :published, city: "Orlando")
      create(:investment_card, :published, city: "Tampa")

      get "/api/v1/investment_cards", params: { city: "orl" }

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("data").map { |card| card.fetch("id") }).to eq([ matching.id ])
    end

    it "does not expose private published cards" do
      create(:investment_card, :published, visibility: "private")

      get "/api/v1/investment_cards"

      expect(json_response["data"]).to be_empty
    end

    it "returns the standard not-found envelope for a missing public card" do
      get "/api/v1/investment_cards/missing-card"

      expect(response).to have_http_status(:not_found)
      expect(json_response.dig("errors", 0, "code")).to eq("not_found")
      expect(json_response["data"]).to be_nil
    end

    it "identifies favorite IDs that are no longer publicly available" do
      visible = create(:investment_card, :published)
      draft = create(:investment_card)

      get "/api/v1/investment_cards", params: { ids: [ visible.id, draft.id, "not-a-uuid" ] }

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("data").map { |card| card.fetch("id") }).to eq([ visible.id ])
      expect(json_response.dig("meta", "unavailable_ids")).to match_array([ draft.id, "not-a-uuid" ])
    end

    it "returns stable pagination metadata" do
      create_list(:investment_card, 3, :published)

      get "/api/v1/investment_cards", params: { page: 2, per_page: 2 }

      expect(response).to have_http_status(:ok)
      expect(json_response["data"].size).to eq(1)
      expect(json_response["meta"]).to include(
        "count" => 3,
        "page" => 2,
        "per_page" => 2,
        "pages" => 2,
        "previous_page" => 1
      )
    end

    it "supports a three-card category preview followed by the complete category listing" do
      residential = create_list(:investment_card, 4, :published, category: "residential")
      create(:investment_card, :published, category: "commercial")
      create(:investment_card, category: "residential")

      get "/api/v1/investment_cards", params: { category: "residential", per_page: 3 }

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("data").size).to eq(3)
      expect(json_response.fetch("meta")).to include("count" => 4, "pages" => 2, "next_page" => 2)

      get "/api/v1/investment_cards", params: { category: "residential" }

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("data").map { |card| card.fetch("id") }).to match_array(residential.map(&:id))
    end

    it "returns an honest empty category preview when no card has been published" do
      create(:investment_card, category: "business")

      get "/api/v1/investment_cards", params: { category: "business", per_page: 3 }

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("data")).to be_empty
      expect(json_response.fetch("meta")).to include("count" => 0, "next_page" => nil)
    end

    it "reproduces page two for combined URL filters with a stable price sort" do
      matches = create_list(
        :investment_card,
        13,
        :published,
        :expert_curated,
        category: "residential",
        city: "Orlando",
        strategy: "renda recorrente",
        price_cents: 500_000_00
      ).sort_by(&:id)
      create(:investment_card, :published, category: "commercial", city: "Orlando")

      get "/api/v1/investment_cards", params: {
        category: "residential",
        city: "Orlando",
        strategy: "renda recorrente",
        expert_curated: "true",
        min_price_cents: 400_000_00,
        max_price_cents: 600_000_00,
        sort: "price_asc",
        page: 2,
        per_page: 12
      }

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("data").map { |card| card.fetch("id") }).to eq([ matches.last.id ])
      expect(json_response.fetch("meta")).to include(
        "count" => 13,
        "page" => 2,
        "per_page" => 12,
        "pages" => 2,
        "previous_page" => 1
      )
    end

    it "sorts by price and uses the card ID as a deterministic tie-breaker" do
      higher = create(:investment_card, :published, price_cents: 900_000_00)
      same_price_later_id = create(:investment_card, :published, price_cents: 500_000_00)
      same_price_earlier_id = create(:investment_card, :published, price_cents: 500_000_00)

      get "/api/v1/investment_cards", params: { sort: "price_asc" }

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("data").map { |card| card.fetch("id") }).to eq(
        [ same_price_earlier_id, same_price_later_id ].sort_by(&:id).map(&:id) + [ higher.id ]
      )
    end

    it "keeps equal-price cards on deterministic pages when sorting descending" do
      cards = create_list(:investment_card, 3, :published, price_cents: 700_000_00).sort_by(&:id)

      get "/api/v1/investment_cards", params: { sort: "price_desc", page: 1, per_page: 2 }
      first_page_ids = json_response.fetch("data").map { |card| card.fetch("id") }

      get "/api/v1/investment_cards", params: { sort: "price_desc", page: 2, per_page: 2 }
      second_page_ids = json_response.fetch("data").map { |card| card.fetch("id") }

      expect(first_page_ids).to eq(cards.first(2).map(&:id))
      expect(second_page_ids).to eq(cards.last(1).map(&:id))
      expect((first_page_ids + second_page_ids).uniq).to eq(cards.map(&:id))
    end

    it "rejects malformed, negative, overflowing, and inverted price filters" do
      invalid_filters = [
        [ { min_price_cents: "12.50" }, "min_price_cents" ],
        [ { max_price_cents: "-1" }, "max_price_cents" ],
        [ { min_price_cents: "9223372036854775808" }, "min_price_cents" ],
        [ { min_price_cents: "500", max_price_cents: "400" }, "min_price_cents" ]
      ]

      invalid_filters.each do |filters, field|
        get "/api/v1/investment_cards", params: filters

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response.dig("errors", 0, "code")).to eq("invalid_price_filter")
        expect(json_response.dig("errors", 0, "field")).to eq(field)
      end
    end
  end

  describe "GET /api/v1/investment_cards/:slug" do
    it "returns a published card by slug" do
      card = create(:investment_card, :published, slug: "published-card")

      get "/api/v1/investment_cards/published-card"

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("data", "id")).to eq(card.id)
      expect(json_response.dig("data", "slug")).to eq("published-card")
    end

    it "removes internal fields and admin document URLs from the public detail payload" do
      card = create(
        :investment_card,
        :published,
        slug: "sanitized-card",
        address_line1: "123 Private Street",
        metadata: { internal_note: "staff only" },
        property_details: { pool: true, total_area: "2,200 SqFt", internal_inspection_note: "staff only" },
        business_details: { seller_name: "Private Seller", internal_valuation: 12_000_000 },
        due_diligence: { legal_notes: "Privileged" },
        financing: { lender_contact: "Private Contact" },
        source_name: "Private Submitter",
        curated_by_id: 123
      )
      card.documents.attach(io: StringIO.new("%PDF-1.4"), filename: "memo.pdf", content_type: "application/pdf")

      get "/api/v1/investment_cards/sanitized-card"

      public_card = json_response.fetch("data")
      expect(response).to have_http_status(:ok)
      expect(public_card).not_to include(
        "metadata", "status", "visibility", "address_line1", "curated_by_id", "source_name",
        "external_reference", "admin_url", "created_at", "updated_at"
      )
      expect(public_card.fetch("documents").first).not_to have_key("admin_url")
      expect(public_card.fetch("documents").first.fetch("public_url")).to include("/documents/")
      expect(public_card.fetch("property_details")).to include("pool" => true, "total_area" => "2,200 SqFt")
      expect(public_card.fetch("property_details")).not_to have_key("internal_inspection_note")
      expect(public_card).not_to include("business_details", "due_diligence", "financing")
    end

    it "returns absolute media URLs for a published card" do
      card = create(:investment_card, :published, slug: "media-card")
      card.cover_image.attach(io: StringIO.new("image"), filename: "cover.jpg", content_type: "image/jpeg")
      card.gallery_images.attach(io: StringIO.new("gallery"), filename: "gallery.jpg", content_type: "image/jpeg")

      get "/api/v1/investment_cards/media-card"

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("data", "cover_image_url")).to start_with("http://localhost:3000/")
      expect(json_response.dig("data", "gallery_image_urls").first).to start_with("http://localhost:3000/")
    end

    it "does not expose private card documents through the public route" do
      card = create(:investment_card, :published, slug: "private-doc-card", visibility: :private)
      card.documents.attach(io: StringIO.new("%PDF-1.4"), filename: "memo.pdf", content_type: "application/pdf")

      get "/api/v1/investment_cards/private-doc-card/documents/#{card.documents.attachments.first.id}"

      expect(response).to have_http_status(:not_found)
    end

    it "provides a public URL and download redirect for a published card document" do
      card = create(:investment_card, :published, slug: "public-doc-card")
      card.documents.attach(io: StringIO.new("%PDF-1.4"), filename: "memo.pdf", content_type: "application/pdf")

      get "/api/v1/investment_cards/public-doc-card"

      document = json_response.dig("data", "documents", 0)
      expect(response).to have_http_status(:ok)
      expect(document).to include("filename" => "memo.pdf", "content_type" => "application/pdf")
      expect(document.fetch("public_url")).to include("/api/v1/investment_cards/public-doc-card/documents/")

      get document.fetch("public_url")

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("/rails/active_storage/blobs/redirect/")
    end
  end

  describe "POST /api/v1/investment_cards/favorites" do
    it "filters and paginates a visitor's favorites when the ID list exceeds 100" do
      cards = create_list(:investment_card, 101, :published)

      post "/api/v1/investment_cards/favorites", params: {
        ids: cards.map(&:id),
        page: 2,
        per_page: 100,
        locale: "es"
      }

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("meta", "count")).to eq(101)
      expect(json_response.dig("meta", "pages")).to eq(2)
      expect(json_response.fetch("data").size).to eq(1)
      expect(json_response.dig("data", 0, "id")).to eq(cards.last.id)
      expect(json_response.dig("data", 0, "locale", "requested_locale")).to eq("es")
    end

    it "rejects empty and oversized ID lists instead of returning the public catalog" do
      post "/api/v1/investment_cards/favorites", params: { ids: [] }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig("errors", 0, "field")).to eq("ids")

      post "/api/v1/investment_cards/favorites", params: { ids: Array.new(10_001) { |index| "card-#{index}" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig("errors", 0, "code")).to eq("invalid_favorite_ids")
    end

    it "rejects invalid price filters for visitor favorites" do
      card = create(:investment_card, :published)

      post "/api/v1/investment_cards/favorites", params: {
        ids: [ card.id ],
        min_price_cents: "not-a-number"
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig("errors", 0, "code")).to eq("invalid_price_filter")
      expect(json_response.dig("errors", 0, "field")).to eq("min_price_cents")
    end
  end

  it "serves a complete reviewed translation and falls back when a required field is missing" do
    card = create(
      :investment_card,
      :published,
      title: "Casa em Orlando",
      summary: "Resumo em português",
      description: "Descrição em português",
      disclaimer: "Aviso informativo",
      alt_text: "Casa branca em Orlando"
    )
    card.update!(metadata: card.metadata.merge(
      "content_locale" => "pt-BR",
      "translations" => {
        "en" => {
          "status" => "published",
          "complete" => true,
          "fields" => {
            "title" => "Orlando home",
            "summary" => "English summary",
            "description" => "English description",
            "disclaimer" => "Informational notice",
            "alt_text" => "White home in Orlando"
          }
        },
        "es" => {
          "status" => "published",
          "complete" => true,
          "fields" => { "title" => "Casa en Orlando" }
        }
      }
    ))

    get "/api/v1/investment_cards/#{card.slug}?locale=en"

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "title")).to eq("Orlando home")
    expect(json_response.dig("data", "locale", "fallback_used")).to be(false)

    get "/api/v1/investment_cards/#{card.slug}?locale=es"

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "title")).to eq("Casa em Orlando")
    expect(json_response.dig("data", "locale", "fallback_used")).to be(true)
  end
end
