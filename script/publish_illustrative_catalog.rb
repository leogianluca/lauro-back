# frozen_string_literal: true

# Manual, opt-in catalog content. These fictional examples are never loaded by
# routine seeds or deploys and must remain identified as illustrative in public.
require "open-uri"

abort "Set ALLOW_ILLUSTRATIVE_CATALOG=1 to run this publication" unless ENV["ALLOW_ILLUSTRATIVE_CATALOG"] == "1"
abort "This script is intended for production" unless Rails.env.production?

asset_base_url = ENV.fetch(
  "PUBLIC_ASSET_BASE_URL",
  "https://d3hcz8rbf098yw.cloudfront.net/lauro-reference/assets"
).delete_suffix("/")

def usd(amount)
  (amount * 100).round
end

residential = [
  { slug: "illustrative-residential-orlando-house", title: "Casa para locação em Orlando", city: "Orlando", asset_type: "single_family", strategy: "renda_recorrente", price_cents: usd(485_000), living_area_sqft: 2_200, bedrooms: 4, bathrooms: 2, year_built: 2006, cap_rate_current: 6.1, image: "preview-residential-single-family.jpg", summary: "Casa unifamiliar com quatro quartos em cenário de locação de longo prazo." },
  { slug: "illustrative-residential-winter-garden-townhouse", title: "Townhouse em Winter Garden", city: "Winter Garden", asset_type: "townhouse", strategy: "renda_recorrente", price_cents: usd(395_000), living_area_sqft: 1_850, bedrooms: 3, bathrooms: 2.5, year_built: 2018, cap_rate_current: 5.8, image: "preview-residential-townhouse.jpg", summary: "Townhouse de três quartos com perfil de renda residencial." },
  { slug: "illustrative-residential-miami-condo", title: "Condomínio residencial em Miami", city: "Miami", asset_type: "condo", strategy: "renda_recorrente", price_cents: usd(620_000), living_area_sqft: 1_350, bedrooms: 2, bathrooms: 2, year_built: 2016, cap_rate_current: 5.5, image: "preview-residential-condo-miami-v1.png", summary: "Apartamento de dois quartos para análise de locação urbana." },
  { slug: "illustrative-residential-lakeland-multifamily", title: "Multifamiliar em Lakeland", city: "Lakeland", asset_type: "multifamily", strategy: "renda_recorrente", price_cents: usd(995_000), living_area_sqft: 3_200, bedrooms: 8, bathrooms: 4, year_built: 1986, cap_rate_current: 7.2, image: "preview-residential-multifamily-lakeland-v1.png", summary: "Conjunto de quatro unidades em cenário de renda e melhoria operacional." },
  { slug: "illustrative-residential-clermont-land", title: "Terreno em Clermont", city: "Clermont", asset_type: "land", strategy: "buy_and_hold", card_level: 1, price_cents: usd(280_000), property_details: { "total_acreage" => 1.2, "total_area" => "1,2 acres" }, image: "area-celebration.png", summary: "Terreno de 1,2 acres para análise de valorização de longo prazo." },
  { slug: "illustrative-residential-tampa-renovation", title: "Casa para reforma em Tampa", city: "Tampa", asset_type: "single_family", strategy: "fix_and_flip", price_cents: usd(375_000), living_area_sqft: 1_740, bedrooms: 3, bathrooms: 2, year_built: 1994, estimated_roi_min: 16, estimated_roi_max: 20, estimated_months: 10, image: "service-residential.jpg", summary: "Casa de três quartos em cenário de reforma e revenda." },
  { slug: "illustrative-residential-kissimmee-build-to-rent", title: "Townhomes Build to Rent em Kissimmee", city: "Kissimmee", asset_type: "townhouse", strategy: "build_to_rent", price_cents: usd(1_263_400), living_area_sqft: 2_200, bedrooms: 4, bathrooms: 2, estimated_months: 14, estimated_roi_min: 16, estimated_roi_max: 20, image: "home-residential-reference-v2.png", summary: "Projeto residencial ilustrativo para construção e locação." },
  { slug: "illustrative-residential-fort-lauderdale-condo", title: "Apartamento em Fort Lauderdale", city: "Fort Lauderdale", asset_type: "condo", strategy: "renda_recorrente", price_cents: usd(540_000), living_area_sqft: 1_260, bedrooms: 2, bathrooms: 2, year_built: 2012, cap_rate_current: 5.9, image: "home-lake.jpg", summary: "Apartamento de dois quartos em cenário de locação de longo prazo." }
].freeze

commercial = [
  { slug: "illustrative-commercial-orlando-retail", title: "Centro de varejo em Orlando", city: "Orlando", asset_type: "retail", price_cents: usd(5_480_000), noi_current_cents: usd(345_000), cap_rate_current: 6.3, occupancy_rate: 92, image: "preview-commercial-retail-v2.jpg", summary: "Centro de varejo em cenário de contratos comerciais diversificados." },
  { slug: "illustrative-commercial-tampa-office", title: "Edifício corporativo em Tampa", city: "Tampa", asset_type: "office", price_cents: usd(7_250_000), noi_current_cents: usd(435_000), cap_rate_current: 6.0, occupancy_rate: 88, image: "home-commercial-reference-v2.png", summary: "Edifício de escritórios com diferentes ocupantes em cenário ilustrativo." },
  { slug: "illustrative-commercial-lakeland-industrial", title: "Galpão industrial em Lakeland", city: "Lakeland", asset_type: "industrial", price_cents: usd(9_750_000), noi_current_cents: usd(643_500), cap_rate_current: 6.6, occupancy_rate: 95, image: "preview-commercial-industrial-v2.jpg", summary: "Galpão industrial em corredor logístico da Flórida Central." },
  { slug: "illustrative-commercial-jacksonville-medical", title: "Centro médico em Jacksonville", city: "Jacksonville", asset_type: "medical_office", price_cents: usd(4_200_000), noi_current_cents: usd(273_000), cap_rate_current: 6.5, occupancy_rate: 90, image: "service-commercial.jpg", summary: "Imóvel de serviços médicos com múltiplas salas comerciais." },
  { slug: "illustrative-commercial-fort-myers-strip-mall", title: "Strip mall em Fort Myers", city: "Fort Myers", asset_type: "retail", price_cents: usd(3_150_000), noi_current_cents: usd(205_000), cap_rate_current: 6.5, occupancy_rate: 86, image: "preview-commercial-retail-v2.jpg", summary: "Conjunto de lojas de bairro em cenário de receita contratual." },
  { slug: "illustrative-commercial-kissimmee-warehouse", title: "Centro de distribuição em Kissimmee", city: "Kissimmee", asset_type: "industrial", price_cents: usd(6_800_000), noi_current_cents: usd(476_000), cap_rate_current: 7.0, occupancy_rate: 97, image: "preview-commercial-industrial-v2.jpg", summary: "Armazém logístico com ocupação simulada de longo prazo." },
  { slug: "illustrative-commercial-miami-mixed-use", title: "Imóvel de uso misto em Miami", city: "Miami", asset_type: "mixed_use", price_cents: usd(8_900_000), noi_current_cents: usd(534_000), cap_rate_current: 6.0, occupancy_rate: 89, image: "home-commercial-reference-v2.png", summary: "Ativo de uso misto com receita comercial e residencial simulada." },
  { slug: "illustrative-commercial-sarasota-storage", title: "Self storage em Sarasota", city: "Sarasota", asset_type: "self_storage", price_cents: usd(5_600_000), noi_current_cents: usd(392_000), cap_rate_current: 7.0, occupancy_rate: 84, image: "service-commercial.jpg", summary: "Operação de armazenagem com indicadores ilustrativos de ocupação." }
].map { |card| card.merge(strategy: "renda_recorrente", investment_min_cents: (card.fetch(:price_cents) * 0.2).round) }.freeze

business = [
  { slug: "illustrative-business-orange-county-restaurant", title: "Restaurante em Orange County", city: "Orange County", asset_type: "restaurant_food", sector: "Alimentação", operating_model: "Restaurante independente", price_cents: usd(650_000), annual_profit_cents: usd(75_000), ebitda_annual_cents: usd(90_000), owner_salary_annual_cents: usd(18_000), owner_time_in_business_years: 4, owner_involvement: "part_time", franchise: false, image: "preview-business-restaurant-v2.jpg", summary: "Restaurante em operação com lucro anual ilustrativo." },
  { slug: "illustrative-business-orlando-cafe", title: "Cafeteria em Orlando", city: "Orlando", asset_type: "restaurant_food", sector: "Alimentação", operating_model: "Cafeteria independente", price_cents: usd(395_000), annual_profit_cents: usd(48_000), ebitda_annual_cents: usd(60_000), owner_salary_annual_cents: usd(22_000), owner_time_in_business_years: 5, owner_involvement: "full_time", franchise: false, image: "preview-business-cafe-v2.jpg", summary: "Cafeteria independente com equipe e operação local simuladas." },
  { slug: "illustrative-business-central-florida-logistics", title: "Empresa de logística na Flórida Central", city: "Central Florida", asset_type: "logistics", sector: "Logística", operating_model: "Serviços B2B", price_cents: usd(1_480_000), annual_profit_cents: usd(165_000), ebitda_annual_cents: usd(200_000), owner_salary_annual_cents: usd(50_000), owner_time_in_business_years: 7, owner_involvement: "part_time", franchise: false, image: "preview-business-logistics-v2.jpg", summary: "Prestadora de serviços logísticos em cenário de aquisição empresarial." },
  { slug: "illustrative-business-tampa-ecommerce", title: "E-commerce em Tampa", city: "Tampa", asset_type: "ecommerce", sector: "Comércio digital", operating_model: "Comércio eletrônico", price_cents: usd(1_500_000), annual_profit_cents: usd(300_000), ebitda_annual_cents: usd(350_000), owner_salary_annual_cents: usd(45_000), owner_time_in_business_years: 6, owner_involvement: "not_involved", franchise: false, image: "home-business-reference-v2.png", summary: "Operação digital com receitas e custos inteiramente fictícios." },
  { slug: "illustrative-business-fort-myers-services", title: "Serviços especializados em Fort Myers", city: "Fort Myers", asset_type: "services", sector: "Serviços", operating_model: "Atendimento B2B", price_cents: usd(780_000), annual_profit_cents: usd(110_000), ebitda_annual_cents: usd(150_000), owner_salary_annual_cents: usd(32_000), owner_time_in_business_years: 9, owner_involvement: "full_time", franchise: false, image: "service-commercial.jpg", summary: "Empresa de serviços especializados em cenário ilustrativo." },
  { slug: "illustrative-business-kissimmee-franchise", title: "Franquia de serviços em Kissimmee", city: "Kissimmee", asset_type: "franchise", sector: "Serviços", operating_model: "Franquia", price_cents: usd(1_050_000), annual_profit_cents: usd(130_000), ebitda_annual_cents: usd(160_000), owner_salary_annual_cents: usd(35_000), owner_time_in_business_years: 3, owner_involvement: "part_time", franchise: true, image: "service-franchise.jpg", summary: "Unidade franqueada fictícia para explorar métricas de aquisição." },
  { slug: "illustrative-business-lakeland-components", title: "Fabricante de componentes em Lakeland", city: "Lakeland", asset_type: "industrial", sector: "Indústria", operating_model: "Manufatura B2B", price_cents: usd(4_300_000), annual_profit_cents: usd(870_000), ebitda_annual_cents: usd(1_000_000), owner_salary_annual_cents: usd(95_000), owner_time_in_business_years: 12, owner_involvement: "full_time", franchise: false, image: "preview-commercial-industrial-v2.jpg", summary: "Indústria de componentes com indicadores operacionais fictícios." },
  { slug: "illustrative-business-sarasota-b2b", title: "Consultoria B2B em Sarasota", city: "Sarasota", asset_type: "services", sector: "Serviços", operating_model: "Consultoria recorrente", price_cents: usd(880_000), annual_profit_cents: usd(180_000), ebitda_annual_cents: usd(220_000), owner_salary_annual_cents: usd(40_000), owner_time_in_business_years: 6, owner_involvement: "part_time", franchise: false, image: "service-brokerage.jpg", summary: "Empresa de serviços recorrentes em cenário de compra ilustrativo." }
].map { |card| card.merge(strategy: "business_acquisition", investment_min_cents: card.fetch(:price_cents)) }.freeze

cards = residential.map { |card| card.merge(category: "residential") } +
  commercial.map { |card| card.merge(category: "commercial") } +
  business.map { |card| card.merge(category: "business") }

abort "Expected exactly eight examples per category" unless cards.group_by { |card| card[:category] }.values.all? { |group| group.length == 8 }

created = []
updated = []

cards.each do |definition|
  image_name = definition.fetch(:image)
  category = definition.fetch(:category)
  attributes = {
    state: "FL", country: "US", card_level: 2, price_currency: "USD",
    market_status: "off_market", featured: false, expert_curated: false,
    financing_available: false, quota_available: false,
    disclaimer: "EXEMPLO ILUSTRATIVO: oportunidade, preço e indicadores são fictícios; este card não representa uma oferta disponível.",
    description: "#{definition.fetch(:summary)} Cenário fictício criado para apresentar como os dados deste tipo de investimento aparecem na plataforma.",
    alt_text: "Imagem ilustrativa de #{definition.fetch(:title).downcase}",
    highlights: [], risks: [], tags: [category, "illustrative"],
    due_diligence: { "status" => "not_applicable", "illustrative" => true },
    financing: {}, property_details: {},
    metadata: { "content_locale" => "pt-BR", "illustrative" => true, "source" => "manual_illustrative_catalog" }
  }.merge(definition.except(:image))

  card = InvestmentCard.unscoped.find_or_initialize_by(slug: definition.fetch(:slug))
  new_card = card.new_record?
  card.assign_attributes(attributes)
  card.status = "draft" if new_card
  card.visibility = "private" if new_card
  card.discarded_at = nil
  card.save!

  unless card.cover_image.attached?
    URI.open("#{asset_base_url}/#{image_name}") do |image|
      card.cover_image.attach(io: image, filename: image_name, content_type: image.content_type)
    end
  end

  card.update!(status: "published", visibility: "public")
  (new_card ? created : updated) << card.slug
end

puts({ created: created.length, updated: updated.length,
  published: InvestmentCard.published.publicly_visible.where(slug: cards.map { |card| card[:slug] }).group(:category).count }.to_json)
