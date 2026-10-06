# frozen_string_literal: true

require "open-uri"

development_opt_in = Rails.env.development? && ENV["ALLOW_DEVELOPMENT"] == "1"
abort "Run with RAILS_ENV=production, or set ALLOW_DEVELOPMENT=1 in development" unless Rails.env.production? || development_opt_in

asset_base_url = ENV.fetch(
  "PUBLIC_ASSET_BASE_URL",
  "https://d3hcz8rbf098yw.cloudfront.net/lauro-reference/assets"
).delete_suffix("/")

common = {
  category: "residential",
  state: "FL",
  country: "US",
  price_currency: "USD",
  market_status: "active",
  featured: true,
  visibility: "private",
  status: "draft",
  disclaimer: "Conteúdo ilustrativo para demonstração da experiência do site. Valores e indicadores não representam uma oferta ou recomendação de investimento.",
  highlights: [],
  risks: [],
  tags: ["residential", "illustrative"],
  due_diligence: {
    "status" => "illustrative",
    "summary" => "Dados demonstrativos, sujeitos a validação antes de qualquer uso comercial."
  },
  financing: {},
  property_details: {},
  metadata: {
    "content_locale" => "pt-BR",
    "illustrative" => true,
    "source" => "approved_public_design_preview"
  }
}.freeze

cards = [
  {
    slug: "4-plex-value-add-orlando",
    title: "4 Plex Value-Add em Orlando, FL",
    summary: "Multifamiliar em Orlando com potencial de renda e valorização.",
    description: "Exemplo ilustrativo de um ativo multifamiliar com quatro unidades e estratégia de melhoria operacional.",
    asset_type: "multifamily",
    strategy: "renda_recorrente",
    city: "Orlando",
    card_level: 3,
    price_cents: 99_500_000,
    investment_min_cents: 19_900_000,
    current_income_cents: 7_200_000,
    projected_income_cents: 8_496_000,
    cap_rate_current: 7.2,
    cap_rate_projected: 8.5,
    cash_on_cash: 9.8,
    occupancy_rate: 100,
    down_payment_percent: 20,
    down_payment_cents: 19_900_000,
    living_area_sqft: 3_200,
    bedrooms: 8,
    bathrooms: 4,
    year_built: 1986,
    estimated_roi_min: 16,
    estimated_roi_max: 20,
    financing_available: true,
    quota_available: true,
    alt_text: "Imagem ilustrativa de um imóvel multifamiliar em Orlando",
    image: "preview-residential-plex.jpg"
  },
  {
    slug: "single-family-rental-kissimmee",
    title: "Single Family Rental",
    summary: "Casa unifamiliar para renda recorrente em Kissimmee.",
    description: "Exemplo ilustrativo de uma residência unifamiliar voltada à estratégia de aluguel de longo prazo.",
    asset_type: "single_family",
    strategy: "renda_recorrente",
    city: "Kissimmee",
    card_level: 2,
    price_cents: 42_800_000,
    investment_min_cents: 8_560_000,
    current_income_cents: 3_120_000,
    projected_income_cents: 3_480_000,
    cap_rate_current: 6.0,
    cap_rate_projected: 7.2,
    gross_yield_percent: 7.3,
    occupancy_rate: 100,
    down_payment_percent: 20,
    down_payment_cents: 8_560_000,
    living_area_sqft: 2_200,
    bedrooms: 4,
    bathrooms: 2,
    year_built: 2006,
    financing_available: true,
    alt_text: "Imagem ilustrativa de uma casa unifamiliar em Kissimmee",
    image: "preview-residential-single-family.jpg"
  },
  {
    slug: "townhouse-fix-flip-winter-garden",
    title: "Townhouse Fix & Flip",
    summary: "Projeto residencial para reforma e revenda em Winter Garden.",
    description: "Exemplo ilustrativo de uma estratégia de reforma e revenda de townhouse.",
    asset_type: "townhouse",
    strategy: "fix_and_flip",
    city: "Winter Garden",
    card_level: 1,
    price_cents: 37_500_000,
    investment_min_cents: 7_500_000,
    estimated_roi_min: 18,
    estimated_roi_max: 22,
    estimated_months: 9,
    financing_available: true,
    alt_text: "Imagem ilustrativa de townhouses em Winter Garden",
    image: "preview-residential-townhouse.jpg"
  },
  {
    slug: "condo-rental-miami",
    title: "Condo Rental em Miami, FL",
    summary: "Condomínio residencial com estratégia de aluguel de longo prazo.",
    description: "Exemplo ilustrativo de um condomínio residencial voltado à renda recorrente.",
    asset_type: "condo",
    strategy: "renda_recorrente",
    city: "Miami",
    card_level: 1,
    price_cents: 32_800_000,
    investment_min_cents: 6_560_000,
    projected_income_cents: 2_230_000,
    cap_rate_current: 6.8,
    cap_rate_projected: 7.3,
    financing_available: true,
    alt_text: "Imagem ilustrativa de condomínio residencial em Miami",
    image: "preview-residential-condo-miami-v1.png"
  },
  {
    slug: "8-units-multifamily-lakeland",
    title: "8 Units Multifamily em Lakeland, FL",
    summary: "Ativo multifamiliar com oito unidades e renda recorrente.",
    description: "Exemplo ilustrativo de um edifício multifamiliar de oito unidades.",
    asset_type: "multifamily",
    strategy: "renda_recorrente",
    city: "Lakeland",
    card_level: 1,
    price_cents: 128_000_000,
    investment_min_cents: 25_600_000,
    projected_income_cents: 9_728_000,
    cap_rate_current: 7.6,
    cap_rate_projected: 8.1,
    financing_available: true,
    alt_text: "Imagem ilustrativa de edifício multifamiliar em Lakeland",
    image: "preview-residential-multifamily-lakeland-v1.png"
  },
  {
    slug: "land-12-acres-clermont",
    title: "Land – 1,2 Acres em Clermont, FL",
    summary: "Terreno para investimento e potencial de valorização.",
    description: "Exemplo ilustrativo de um terreno de 1,2 acres para uma estratégia de longo prazo.",
    asset_type: "land",
    strategy: "buy_and_hold",
    city: "Clermont",
    card_level: 2,
    price_cents: 28_000_000,
    investment_min_cents: 5_600_000,
    hpi_10_year_percent: 10,
    property_details: { "total_acreage" => 1.2, "total_area" => "1,2 acres" },
    alt_text: "Imagem ilustrativa de terreno em Clermont",
    image: "area-celebration.png"
  }
].freeze

admin = User.find_by(role: "admin")
created = []
updated = []

cards.each_with_index do |definition, index|
  image_name = definition.fetch(:image)
  attributes = common.merge(definition.except(:image)).merge(featured_position: index + 1)
  card = InvestmentCard.unscoped.find_or_initialize_by(slug: definition.fetch(:slug))
  was_new = card.new_record?

  if definition[:slug].in?(%w[
    4-plex-value-add-orlando
    single-family-rental-kissimmee
    8-units-multifamily-lakeland
  ]) && admin
    attributes = attributes.merge(
      expert_curated: true,
      curated_by: admin,
      source_name: "Florida Investments",
      verified_at: Time.current,
      expert_curated_reason: "Card selecionado para compor a experiência pública aprovada.",
      expert_curated_analysis: "Conteúdo ilustrativo; valide dados e disponibilidade antes de uso comercial."
    )
  else
    attributes = attributes.merge(expert_curated: false, curated_by: nil)
  end

  card.assign_attributes(attributes)
  card.discarded_at = nil
  card.save!

  unless card.cover_image.attached?
    URI.open("#{asset_base_url}/#{image_name}") do |image|
      card.cover_image.attach(
        io: image,
        filename: image_name,
        content_type: image.content_type
      )
    end
  end

  card.update!(status: "published", visibility: "public", published_at: card.published_at || Time.current)
  (was_new ? created : updated) << card.slug
end

puts({ created:, updated:, published_residential: InvestmentCard.published.publicly_visible.where(category: "residential").count }.to_json)
