require "rails_helper"

RSpec.describe InvestmentCard, type: :model do
  subject(:investment_card) { build(:investment_card) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_inclusion_of(:card_level).in_range(1..3) }

  it "supports optional broker, company and location relationships" do
    card = create(
      :investment_card,
      investment_broker: create(:investment_broker),
      investment_company: create(:investment_company),
      investment_location: create(:investment_location)
    )

    expect(card.reload).to have_attributes(
      investment_broker: be_present,
      investment_company: be_present,
      investment_location: be_present
    )
  end

  it "requires list and object shapes for structured metadata" do
    card = build(:investment_card, tags: { name: "luxury" }, due_diligence: [])

    expect(card).not_to be_valid
    expect(card.errors[:tags]).to include("must be a list of text values")
    expect(card.errors[:due_diligence]).to include("must be an object")
  end

  it "generates a slug when none is provided" do
    card = create(:investment_card, title: "4 Plex Value Add", slug: nil)

    expect(card.slug).to eq("4-plex-value-add")
  end

  it "marks a draft card as published" do
    card = create(:investment_card)
    card.cover_image.attach(
      io: Rails.root.join("spec/fixtures/files/test-image.svg").open,
      filename: "test-image.svg",
      content_type: "image/svg+xml"
    )

    card.publish!

    expect(card).to be_published
    expect(card.published_at).to be_present
  end

  it "sets the publication date when the admin saves a published status directly" do
    card = create(:investment_card)
    card.cover_image.attach(
      io: Rails.root.join("spec/fixtures/files/test-image.svg").open,
      filename: "test-image.svg",
      content_type: "image/svg+xml"
    )

    card.update!(status: :published)

    expect(card.reload).to be_published
    expect(card.published_at).to be_present
  end

  it "does not replace the original publication date on later edits" do
    card = create(:investment_card, :published)
    original_date = card.published_at

    card.update!(summary: "Updated description for investors")

    expect(card.reload.published_at).to eq(original_date)
  end

  it "requires business fields for published business cards" do
    card = build(:investment_card, status: :published, category: "Business", sector: nil, operating_model: nil, ebitda_annual_cents: nil)
    card.cover_image.attach(
      io: Rails.root.join("spec/fixtures/files/test-image.svg").open,
      filename: "cover.svg",
      content_type: "image/svg+xml"
    )

    expect(card).not_to be_valid
    expect(card.errors[:sector]).to be_present
    expect(card.errors[:operating_model]).to be_present
    expect(card.errors[:ebitda_annual_cents]).to be_present
  end

  it "uses land area instead of building fields for published residential land" do
    card = build(:investment_card, :published, card_level: 2, asset_type: "land",
      property_details: { "total_acreage" => "1.2" })

    expect(card).to be_valid
    card.property_details = {}
    expect(card).not_to be_valid
    expect(card.errors[:property_details]).to be_present
  end

  it "does not require a construction year for a new-build project" do
    card = build(:investment_card, :published, card_level: 2, strategy: "build_to_sell",
      estimated_months: 12, living_area_sqft: 2_000, bedrooms: 3, bathrooms: 2,
      year_built: nil)

    expect(card).to be_valid
  end

  it "does not publish a zero-priced opportunity" do
    card = build(:investment_card, :published, price_cents: 0)

    expect(card).not_to be_valid
    expect(card.errors[:price_cents]).to be_present
  end

  it "does not publish an Expert Curated badge without a documented review" do
    card = build(:investment_card, :published, expert_curated: true)

    expect(card).not_to be_valid
    expect(card.errors[:curated_by_id]).to be_present
    expect(card.errors[:source_name]).to be_present
    expect(card.errors[:verified_at]).to be_present
    expect(card.errors[:expert_curated_reason]).to be_present
  end

  it "limits published residential featured cards to three" do
    create_list(:investment_card, 3, :published, featured: true, category: "residential")
    fourth = build(:investment_card, :published, featured: true, category: "residential")

    expect(fourth).not_to be_valid
    expect(fourth.errors[:featured]).to include("allows at most three published residential opportunities")

    commercial = build(:investment_card, :published, featured: true, category: "commercial")
    expect(commercial).to be_valid
  end
end
