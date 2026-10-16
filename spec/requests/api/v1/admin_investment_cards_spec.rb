require "rails_helper"
require "tempfile"

RSpec.describe "Admin investment cards", type: :request do
  def write_image(tempfile, format, width: 640, height: 360)
    tempfile.binmode
    tempfile.write(Vips::Image.black(width, height).write_to_buffer(format))
    tempfile.close
  end

  describe "POST /api/v1/admin/investment_cards" do
    it "allows an editor to create a card" do
      editor = create(:user, :editor)

      post "/api/v1/admin/investment_cards",
           params: { investment_card: attributes_for(:investment_card, title: "New Deal", tags: [ "luxury", "miami" ], highlights: [ "High demand" ], risks: [ "Market cycle" ], due_diligence: { status: "in_review" }, financing: { type: "bank" }) },
           headers: auth_headers_for(editor)

      expect(response).to have_http_status(:created)
      expect(json_response.dig("data", "title")).to eq("New Deal")
      expect(json_response.dig("data", "tags")).to eq([ "luxury", "miami" ])
      expect(json_response.dig("data", "due_diligence", "status")).to eq("in_review")
    end

    it "accepts optional residential yield indicators from the editor" do
      editor = create(:user, :editor)

      post "/api/v1/admin/investment_cards",
           params: { investment_card: attributes_for(:investment_card,
             gross_yield_percent: 8.7, hpi_10_year_percent: 42.5) },
           headers: auth_headers_for(editor)

      expect(response).to have_http_status(:created)
      expect(json_response.dig("data", "gross_yield_percent").to_f).to eq(8.7)
      expect(json_response.dig("data", "hpi_10_year_percent").to_f).to eq(42.5)
    end

    it "stores commercial amounts, percentages and technical details from the editor" do
      editor = create(:user, :editor)

      post "/api/v1/admin/investment_cards",
        params: { investment_card: attributes_for(:investment_card,
          category: "commercial", asset_type: "office", strategy: "build_to_rent",
          price_cents: 1_250_000_000, cap_rate_current: 7.25,
          property_details: { unit_count: 4, price_per_sqft: 315.5, stabilized_yield_on_cost: 8.125 }) },
        headers: auth_headers_for(editor)

      expect(response).to have_http_status(:created)
      card = InvestmentCard.find(json_response.dig("data", "id"))
      expect(card.price_cents).to eq(1_250_000_000)
      expect(card.cap_rate_current.to_f).to eq(7.25)
      expect(card.property_details).to include("unit_count" => 4, "price_per_sqft" => 315.5, "stabilized_yield_on_cost" => 8.125)
    end

    it "rejects malformed currency and percentage values before saving" do
      editor = create(:user, :editor)
      invalid_values = [
        [ { price_cents: "12.50" }, "price_cents" ],
        [ { cap_rate_current: "7,25" }, "cap_rate_current" ],
        [ { property_details: { price_per_sqft: "1,200" } }, "property_details.price_per_sqft" ],
        [ { business_details: { gross_revenue_cents: "100.25" } }, "business_details.gross_revenue_cents" ]
      ]

      invalid_values.each do |attributes, field|
        post "/api/v1/admin/investment_cards",
          params: { investment_card: attributes_for(:investment_card).merge(attributes) },
          headers: auth_headers_for(editor)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response.dig("errors", 0, "field")).to eq(field)
      end
    end

    it "rejects a viewer" do
      viewer = create(:user, :viewer)

      post "/api/v1/admin/investment_cards",
           params: { investment_card: attributes_for(:investment_card) },
           headers: auth_headers_for(viewer)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/admin/investment_cards" do
    it "filters the internal list to featured cards within a category" do
      editor = create(:user, :editor)
      featured = create(:investment_card, featured: true, category: "residential")
      create(:investment_card, featured: false, category: "residential")
      create(:investment_card, featured: true, category: "commercial")

      get "/api/v1/admin/investment_cards",
        params: { category: "residential", featured: "true" },
        headers: auth_headers_for(editor)

      expect(response).to have_http_status(:ok)
      expect(json_response.fetch("data").map { |record| record.fetch("id") }).to eq([ featured.id ])
    end
  end

  describe "card lifecycle" do
    it "keeps detail reads separate from making a private card public" do
      viewer = create(:user, :viewer)
      editor = create(:user, :editor)
      card = create(:investment_card, visibility: :private)

      get "/api/v1/admin/investment_cards/#{card.id}", headers: auth_headers_for(viewer)
      expect(response).to have_http_status(:ok)
      expect(card.reload).to be_visibility_private

      patch "/api/v1/admin/investment_cards/#{card.id}/show", headers: auth_headers_for(viewer)
      expect(response).to have_http_status(:forbidden)
      expect(card.reload).to be_visibility_private

      patch "/api/v1/admin/investment_cards/#{card.id}/show", headers: auth_headers_for(editor)
      expect(response).to have_http_status(:ok)
      expect(card.reload).to be_visibility_public
    end

    it "publishes with a timestamp when status is changed through the editor form" do
      editor = create(:user, :editor)
      card = create(:investment_card)
      card.cover_image.attach(
        io: Rails.root.join("spec/fixtures/files/test-image.svg").open,
        filename: "test-image.svg",
        content_type: "image/svg+xml"
      )

      patch "/api/v1/admin/investment_cards/#{card.id}",
        params: { investment_card: { status: "published" } },
        headers: auth_headers_for(editor)

      expect(response).to have_http_status(:ok)
      expect(card.reload.status).to eq("published")
      expect(card.reload.published_at).to be_present

      get "/api/v1/investment_cards", params: { category: card.category }
      expect(json_response.fetch("data").map { |record| record.fetch("id") }).to include(card.id)
    end

    it "lets an editor publish and hide a card" do
      editor = create(:user, :editor)
      card = create(:investment_card)
      card.cover_image.attach(
        io: Rails.root.join("spec/fixtures/files/test-image.svg").open,
        filename: "test-image.svg",
        content_type: "image/svg+xml"
      )
      headers = auth_headers_for(editor)

      patch "/api/v1/admin/investment_cards/#{card.id}/publish", headers: headers
      expect(response).to have_http_status(:ok)
      expect(card.reload).to be_published

      patch "/api/v1/admin/investment_cards/#{card.id}/hide", headers: headers
      expect(response).to have_http_status(:ok)
      expect(card.reload.visibility).to eq("private")
    end

    it "allows only an admin to discard a card" do
      editor = create(:user, :editor)
      card = create(:investment_card)

      delete "/api/v1/admin/investment_cards/#{card.id}", headers: auth_headers_for(editor)
      expect(response).to have_http_status(:forbidden)
      expect(card.reload).not_to be_discarded

      admin = create(:user, :admin)
      delete "/api/v1/admin/investment_cards/#{card.id}", headers: auth_headers_for(admin)
      expect(response).to have_http_status(:ok)
      expect(card.reload).to be_discarded
    end
  end

  describe "POST /api/v1/admin/investment_cards/:id/media" do
    it "attaches one cover and multiple gallery files" do
      editor = create(:user, :editor)
      card = create(:investment_card)
      cover = Tempfile.new([ "cover", ".png" ])
      gallery = Tempfile.new([ "gallery", ".jpg" ])
      write_image(cover, ".png")
      write_image(gallery, ".jpg[Q=80]")

      post "/api/v1/admin/investment_cards/#{card.id}/media",
           params: {
             cover_image: Rack::Test::UploadedFile.new(cover.path, "image/png"),
             gallery_images: [ Rack::Test::UploadedFile.new(gallery.path, "image/jpeg") ]
           },
           headers: auth_headers_for(editor)

      expect(response).to have_http_status(:ok)
      expect(card.reload.cover_image).to be_attached
      expect(card.gallery_images).to be_attached
      expect(json_response.dig("data", "gallery_images_count")).to eq(1)
    ensure
      cover&.unlink
      gallery&.unlink
    end

  it "requires authentication to access a card document" do
      admin = create(:user, :admin)
      card = create(:investment_card)
      card.documents.attach(io: StringIO.new("%PDF-1.4"), filename: "memo.pdf", content_type: "application/pdf")
      attachment_id = card.documents.attachments.first.id

      get "/api/v1/admin/investment_cards/#{card.id}/documents/#{attachment_id}", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:redirect)
      expect(response.headers["Location"]).to include("/rails/active_storage/blobs/redirect/")
    end

    it "rejects unsupported files" do
      editor = create(:user, :editor)
      card = create(:investment_card)
      file = Tempfile.new([ "script", ".exe" ])
      file.write("not an image")
      file.close

      post "/api/v1/admin/investment_cards/#{card.id}/media",
           params: { cover_image: Rack::Test::UploadedFile.new(file.path, "application/octet-stream") },
           headers: auth_headers_for(editor)

      expect(response).to have_http_status(:unprocessable_content)
      expect(card.reload.cover_image).not_to be_attached
    ensure
      file&.unlink
    end

    it "rejects an image below the minimum dimensions" do
      editor = create(:user, :editor)
      card = create(:investment_card)
      file = Tempfile.new([ "small", ".png" ])
      write_image(file, ".png", width: 319, height: 180)

      post "/api/v1/admin/investment_cards/#{card.id}/media",
           params: { cover_image: Rack::Test::UploadedFile.new(file.path, "image/png") },
           headers: auth_headers_for(editor)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response.dig("errors", 0, "message")).to include("320x180")
      expect(card.reload.cover_image).not_to be_attached
    ensure
      file&.unlink
    end
  end

  it "queues removal of a card attachment" do
    editor = create(:user, :editor)
    card = create(:investment_card)
    card.documents.attach(io: StringIO.new("%PDF-1.4"), filename: "memo.pdf", content_type: "application/pdf")
    attachment_id = card.documents.attachments.first.id

    delete "/api/v1/admin/investment_cards/#{card.id}/media/documents/#{attachment_id}", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:accepted)
    expect(json_response.dig("data", "status")).to eq("queued")
  end
end
