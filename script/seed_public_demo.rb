# Run with: bin/rails runner script/seed_public_demo.rb
# Deliberately separate from db:seed: these fictional public records must never
# be created by a routine production setup or deployment.
abort "Public demo content is development-only" unless Rails.env.development?

assets = Rails.root.parent.join("minimal_typescript_v7", "public", "lauro-reference", "assets")

def attach_demo_image(record, path)
  raise "Missing demo image: #{path}" unless File.file?(path)
  return if record.cover_image.attached?

  content_type = path.extname.downcase == ".png" ? "image/png" : "image/jpeg"
  File.open(path, "rb") do |file|
    record.cover_image.attach(io: file, filename: path.basename.to_s, content_type: content_type)
  end
end

deals = [
  ["residential", "single_family", "renda_imediata", "Casa demonstrativa em Orlando", "Orlando", 485_000, "preview-residential-single-family.jpg"],
  ["residential", "condo", "renda_recorrente", "Condomínio demonstrativo em Miami", "Miami", 620_000, "preview-residential-condo-miami-v1.png"],
  ["residential", "townhouse", "value_add", "Townhouse demonstrativa em Tampa", "Tampa", 395_000, "preview-residential-townhouse.jpg"],
  ["residential", "multifamily", "renda_recorrente", "Multifamily demonstrativo em Lakeland", "Lakeland", 980_000, "preview-residential-multifamily-lakeland-v1.png"],
  ["commercial", "office", "renda_imediata", "Escritório demonstrativo em Orlando", "Orlando", 2_850_000, "home-commercial-reference-v2.png"],
  ["commercial", "retail", "value_add", "Retail demonstrativo em Tampa", "Tampa", 1_750_000, "preview-commercial-retail-v2.jpg"],
  ["commercial", "industrial", "renda_recorrente", "Galpão demonstrativo em Lakeland", "Lakeland", 3_100_000, "preview-commercial-industrial-v2.jpg"],
  ["commercial", "mixed_use", "value_add", "Mixed-use demonstrativo em Miami", "Miami", 4_250_000, "home-commercial-reference-v2.png"],
  ["business", "restaurant_food", "renda_imediata", "Cafeteria demonstrativa em Orlando", "Orlando", 420_000, "preview-business-cafe-v2.jpg"],
  ["business", "restaurant_food", "renda_recorrente", "Restaurante demonstrativo em Tampa", "Tampa", 650_000, "preview-business-restaurant-v2.jpg"],
  ["business", "restaurant_food", "value_add", "Logística demonstrativa em Miami", "Miami", 1_480_000, "preview-business-logistics-v2.jpg"],
  ["business", "restaurant_food", "renda_recorrente", "Serviços demonstrativos em Orlando", "Orlando", 780_000, "home-business-reference-v2.png"]
]

deals.each_with_index do |(category, asset_type, strategy, title, city, price, image), index|
  slug = "public-demo-#{category}-#{index + 1}"
  next if InvestmentCard.exists?(slug: slug)

  card = InvestmentCard.new(
    slug: slug, title: "[DEMO] #{title}",
    summary: "Exemplo fictício para testar a navegação e apresentação de oportunidades.",
    description: "Oportunidade inteiramente simulada. Valores, disponibilidade e indicadores não representam um ativo à venda.",
    category: category, asset_type: asset_type, strategy: strategy, city: city, state: "FL",
    price_cents: price * 100, price_currency: "USD", card_level: 1,
    status: "draft", visibility: "public", featured: index % 4 < 3,
    featured_position: index % 4 + 1, expert_curated: false,
    market_status: "active", sector: category == "business" ? "Serviços" : nil,
    operating_model: category == "business" ? "Operação simulada" : nil,
    ebitda_annual_cents: category == "business" ? (price * 0.12 * 100).to_i : nil,
    alt_text: "Imagem ilustrativa de #{title.downcase}",
    disclaimer: "DEMONSTRAÇÃO: oportunidade, preço e dados fictícios. Não constitui oferta ou recomendação de investimento.",
    highlights: ["Conteúdo demonstrativo", "Fluxo de navegação e contato disponível"],
    risks: ["Dados fictícios; não usar para decisão de investimento"],
    tags: ["demo", category],
    due_diligence: { "status" => "not_applicable", "demo" => true },
    financing: {}
  )
  card.save!
  attach_demo_image(card, assets.join(image))
  card.publish!
end

category_names = {
  "residential" => ["residential", "residencial"],
  "commercial" => ["commercial", "comercial"],
  "business" => ["business", "negocio"]
}
InvestmentCard.where(slug: deals.each_index.map { |index| "public-demo-#{deals[index][0]}-#{index + 1}" }).find_each do |card|
  english_category, spanish_category = category_names.fetch(card.category)
  card.update!(metadata: card.metadata.merge(
    "demo" => true, "content_locale" => "pt-BR",
    "translations" => {
      "en" => { "status" => "published", "complete" => true, "fields" => {
        "title" => "[DEMO] #{card.city} #{english_category} opportunity",
        "summary" => "Fictional example for testing the opportunity browsing experience.",
        "description" => "Entirely simulated opportunity. Prices, availability and indicators do not represent an asset for sale.",
        "alt_text" => "Illustrative image of a #{english_category} opportunity in #{card.city}",
        "disclaimer" => "DEMO: fictional opportunity, price and data. Not an offer or investment recommendation.",
        "highlights" => ["Demonstration content", "Browsing and contact flow available"],
        "risks" => ["Fictional data; do not use for investment decisions"]
      } },
      "es" => { "status" => "published", "complete" => true, "fields" => {
        "title" => "[DEMO] Oportunidad #{spanish_category} en #{card.city}",
        "summary" => "Ejemplo ficticio para probar la navegación de oportunidades.",
        "description" => "Oportunidad completamente simulada. Los precios, la disponibilidad y los indicadores no representan un activo en venta.",
        "alt_text" => "Imagen ilustrativa de una oportunidad #{spanish_category} en #{card.city}",
        "disclaimer" => "DEMO: oportunidad, precio y datos ficticios. No constituye una oferta ni recomendación de inversión.",
        "highlights" => ["Contenido de demostración", "Navegación y contacto disponibles"],
        "risks" => ["Datos ficticios; no usar para decisiones de inversión"]
      } }
    }
  ))
end

edition = NewsletterEdition.find_or_initialize_by(slug: "public-demo-newsletter-setembro-2026")
if edition.new_record?
  edition.assign_attributes(
    title: "[DEMO] Newsletter — setembro de 2026",
    excerpt: "Edição fictícia para demonstrar a leitura de conteúdos da plataforma.",
    body: "EDIÇÃO DEMONSTRATIVA. Este conteúdo não contém dados atuais de mercado. A newsletter real reunirá indicadores econômicos, contexto imobiliário e oportunidades aprovadas pela equipe.",
    edition_date: Date.new(2026, 9, 15), status: "draft", visibility: "public",
    cta_label: "Explorar oportunidades", cta_url: "/opportunities",
    metadata: { "demo" => true, "content_locale" => "pt-BR" }
  )
  edition.save!
  attach_demo_image(edition, assets.join("newsletter-hero-editorial-v1.png"))
  edition.publish!
end
edition.update!(metadata: edition.metadata.merge("demo" => true, "content_locale" => "pt-BR", "translations" => {
  "en" => { "status" => "published", "complete" => true, "fields" => {
    "title" => "[DEMO] Newsletter — September 2026",
    "excerpt" => "Fictional issue demonstrating the platform's editorial reading experience.",
    "body" => "DEMONSTRATION ISSUE. This content does not contain current market data. The real newsletter will bring economic indicators, real-estate context and team-approved opportunities.",
    "cta_label" => "Explore opportunities"
  } },
  "es" => { "status" => "published", "complete" => true, "fields" => {
    "title" => "[DEMO] Newsletter — septiembre de 2026",
    "excerpt" => "Edición ficticia para demostrar la lectura de contenidos de la plataforma.",
    "body" => "EDICIÓN DEMOSTRATIVA. Este contenido no contiene datos actuales del mercado. La newsletter real reunirá indicadores económicos, contexto inmobiliario y oportunidades aprobadas por el equipo.",
    "cta_label" => "Explorar oportunidades"
  } }
}))

report = MarketReport.find_or_initialize_by(slug: "public-demo-market-report-setembro-2026")
if report.new_record?
  report.assign_attributes(
    title: "[DEMO] Market Report — setembro de 2026", period: "2026-09",
    excerpt: "Relatório fictício para demonstrar a navegação e a apresentação editorial.",
    body: "RELATÓRIO DEMONSTRATIVO. Os indicadores abaixo são simulados e não descrevem o mercado atual. A versão real deverá informar período, metodologia e fontes verificáveis antes de publicação.",
    market_name: "Flórida", region: "Demonstração", source_name: "Dados simulados — não usar para investimento",
    metrics: { "demo" => true, "vacancy_rate" => 6.1, "average_cap_rate" => 6.4 },
    metadata: { "demo" => true }, status: "published", visibility: "public"
  )
  report.save!
  report.market_report_metrics.create!(label: "Vacância simulada", value: "6.1", unit: "%", featured: true)
  report.market_report_metrics.create!(label: "Cap rate simulado", value: "6.4", unit: "%", featured: true)
end
report.update!(metadata: report.metadata.merge("demo" => true, "content_locale" => "pt-BR", "translations" => {
  "en" => { "status" => "published", "complete" => true, "fields" => {
    "title" => "[DEMO] Market Report — September 2026",
    "excerpt" => "Fictional report demonstrating the editorial layout and navigation.",
    "body" => "DEMONSTRATION REPORT. The indicators shown here are simulated and do not describe the current market. A real edition must include a period, methodology and verifiable sources before publication."
  } },
  "es" => { "status" => "published", "complete" => true, "fields" => {
    "title" => "[DEMO] Informe de mercado — septiembre de 2026",
    "excerpt" => "Informe ficticio para demostrar la navegación y presentación editorial.",
    "body" => "INFORME DEMOSTRATIVO. Los indicadores mostrados son simulados y no describen el mercado actual. La versión real deberá incluir período, metodología y fuentes verificables antes de publicarse."
  } }
}))

puts "Public demo: #{InvestmentCard.published.publicly_visible.where('slug LIKE ?', 'public-demo-%').count} deals, " \
     "#{NewsletterEdition.published_for_public.where('slug LIKE ?', 'public-demo-%').count} newsletter, " \
     "#{MarketReport.published_for_public.where('slug LIKE ?', 'public-demo-%').count} report"
