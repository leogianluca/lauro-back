# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
if Rails.env.development?
  User.find_or_create_by!(email: "admin@example.com") do |user|
    user.name = "Lauro Admin"
    user.password = ENV.fetch("SEED_ADMIN_PASSWORD") { SecureRandom.base58(32) }
    user.role = "admin"
  end

  puts "Seeded development administrator"
end

if Rails.env.development?
  taxonomy_seed = {
    "category" => {
      "residential" => "Residencial",
      "commercial" => "Comercial",
      "business" => "Empresas"
    },
    "asset_type" => {
      "single_family" => "Single Family", "condo" => "Condomínio", "townhouse" => "Townhouse",
      "multifamily" => "Multifamily", "duplex" => "Duplex", "triplex" => "Triplex", "land" => "Terreno", "retail" => "Retail",
      "office" => "Office", "industrial" => "Industrial", "hospitality" => "Hospitality",
      "mixed_use" => "Mixed-Use", "restaurant_food" => "Restaurants & Food"
    },
    "strategy" => {
      "renda_imediata" => "Renda imediata", "renda_recorrente" => "Renda recorrente",
      "flip" => "Reforma + venda", "build_to_sell" => "Build to Sell",
      "build_to_rent" => "Build to Rent", "value_add" => "Value-add", "development" => "Desenvolvimento"
    },
    "market" => { "orlando" => "Orlando", "tampa" => "Tampa", "lakeland" => "Lakeland", "miami" => "Miami", "orange_county" => "Orange County" },
    "metric_type" => {
      "currency" => "Moeda", "percentage" => "Percentual", "duration" => "Prazo",
      "area" => "Área", "count" => "Quantidade"
    },
    "market_status" => { "active" => "Ativo", "pending" => "Pendente", "closed" => "Encerrado", "off_market" => "Off market" },
    "tag" => { "expert_curated" => "Expert Curated", "featured" => "Destaque", "new" => "Novo", "high_demand" => "Alta demanda" }
  }
  taxonomy_seed.each do |kind, terms|
    terms.each_with_index do |(slug, name), position|
      term = TaxonomyTerm.find_or_initialize_by(kind:, slug:)
      term.assign_attributes(name:, position:, active: true)
      term.save!
    end
  end

  demo_asset = lambda do |relative_path|
    path = Rails.root.parent.join("minimal_typescript_v7", "public", "assets", "images", relative_path)
    File.exist?(path) ? path : nil
  end

  demo_images = %w[about/hero.webp about/vision.webp about/testimonials.webp].filter_map { |path| demo_asset.call(path) }
  business_demo_image = demo_asset.call("lauro/business-level-2.png")
  admin = User.find_by!(email: "admin@example.com")

  [
    {
      slug: "multifamily-value-add-orlando-demo",
      title: "Multifamily Value-Add em Orlando, FL",
      summary: "Ativo residencial com renda recorrente e potencial de valorização.",
      description: "Oportunidade multifamiliar em região de alta demanda, com tese de melhoria operacional e acompanhamento especializado.",
      category: "residential", asset_type: "multifamily", strategy: "renda_recorrente", city: "Orlando", state: "FL",
      price_cents: 995_000_00, investment_min_cents: 199_000_00, current_income_cents: 72_000_00, projected_income_cents: 84_960_00,
      noi_current_cents: 61_200_00, noi_projected_cents: 72_216_00, cap_rate_current: 7.2, cap_rate_projected: 8.5, cash_on_cash: 9.8, occupancy_rate: 100,
      market_status: "active", down_payment_percent: 20.0, down_payment_cents: 199_000_00, living_area_sqft: 3_200, bedrooms: 8, bathrooms: 4,
      year_built: 1986, estimated_roi_min: 16.0, estimated_roi_max: 20.0, equity_generated_min_cents: 90_000_00, equity_generated_max_cents: 120_000_00,
      financing_available: true, quota_available: true,
      property_details: { "property_style" => "Multifamily", "lp_per_sqft" => "$311", "can_be_leased" => true, "new_construction" => false,
                          "pool" => "None", "minimum_lease_period" => "12 months", "heated_area" => "3,200 SqFt / 297.29 SqM",
                          "garage" => true, "pets" => true, "total_area" => "3,200 SqFt / 297.29 SqM", "garage_spaces" => 8,
                          "special_sale" => "None", "total_acreage" => 0.23, "subdivision" => "Orlando" },
      highlights: [ "Localização com alta demanda de locação", "Quatro unidades com renda recorrente", "Potencial de aumento de receita" ],
      risks: [ "Execução das melhorias dentro do orçamento", "Variação de taxas de juros" ],
      card_level: 3, expert_curated: true
    },
    {
      slug: "single-family-rental-tampa-demo",
      title: "Single Family Rental em Tampa, FL",
      summary: "Imóvel residencial para renda de longo prazo.",
      description: "Casa unifamiliar em mercado consolidado, adequada para uma estratégia de renda estável e valorização patrimonial.",
      category: "residential", asset_type: "single_family", strategy: "renda_recorrente", city: "Tampa", state: "FL",
      price_cents: 435_000_00, investment_min_cents: 87_000_00, current_income_cents: 31_320_00, projected_income_cents: 34_800_00,
      noi_current_cents: 26_600_00, noi_projected_cents: 29_580_00, cap_rate_current: 7.2, cap_rate_projected: 8.0, cash_on_cash: 8.4, occupancy_rate: 100,
      market_status: "active", down_payment_percent: 20.0, down_payment_cents: 87_000_00, living_area_sqft: 2_200, bedrooms: 4, bathrooms: 2,
      year_built: 2006, estimated_roi_min: 16.0, estimated_roi_max: 20.0, equity_generated_min_cents: 90_000_00, equity_generated_max_cents: 120_000_00,
      financing_available: true, quota_available: true,
      property_details: { "property_style" => "Single Family Residence", "lp_per_sqft" => "$198", "can_be_leased" => true, "new_construction" => false,
                          "pool" => "Private", "minimum_lease_period" => "No minimum", "heated_area" => "2,200 SqFt / 204.39 SqM",
                          "garage" => true, "pets" => true, "total_area" => "2,200 SqFt / 204.39 SqM", "garage_spaces" => 2,
                          "special_sale" => "None", "total_acreage" => 0.18, "subdivision" => "Tampa" },
      highlights: [ "Demanda habitacional consistente", "Baixa complexidade operacional" ],
      risks: [ "Manutenção e vacância local" ],
      card_level: 2, expert_curated: false
    },
    {
      slug: "retail-center-lakeland-demo",
      title: "Retail Center em Lakeland, FL",
      summary: "Ativo comercial com contratos e localização estratégica.",
      description: "Centro comercial com potencial de renda recorrente e exposição a uma região em crescimento.",
      category: "commercial", asset_type: "retail", strategy: "renda_imediata", city: "Lakeland", state: "FL",
      price_cents: 2_180_000_00, investment_min_cents: 436_000_00, current_income_cents: 176_580_00, projected_income_cents: 189_660_00,
      noi_current_cents: 141_700_00, noi_projected_cents: 152_280_00, cap_rate_current: 6.5, cap_rate_projected: 6.9, cash_on_cash: 7.6, occupancy_rate: 100,
      market_status: "active", down_payment_percent: 20.0, down_payment_cents: 436_000_00, living_area_sqft: 18_000, bedrooms: 0, bathrooms: 4,
      year_built: 2018, estimated_roi_min: 8.0, estimated_roi_max: 12.0, equity_generated_min_cents: 180_000_00, equity_generated_max_cents: 260_000_00,
      financing_available: true, quota_available: false,
      property_details: { "property_style" => "Retail Center", "lp_per_sqft" => "$121", "can_be_leased" => true, "new_construction" => false,
                          "pool" => "N/A", "minimum_lease_period" => "5 years", "heated_area" => "18,000 SqFt / 1,672.25 SqM",
                          "garage" => true, "pets" => false, "total_area" => "18,000 SqFt / 1,672.25 SqM", "garage_spaces" => 80,
                          "special_sale" => "None", "total_acreage" => 1.8, "subdivision" => "Lakeland" },
      highlights: [ "Contratos comerciais ativos", "Alta visibilidade e acesso" ],
      risks: [ "Ciclos econômicos do varejo" ],
      card_level: 2, expert_curated: false
    },
    {
      slug: "restaurant-food-orange-county-demo",
      title: "Restaurant & Food Business em Orange County, FL",
      summary: "Negócio de alimentação estabelecido com operação ativa e financiamento do vendedor.",
      description: "Empresa de alimentação em operação, com histórico de lucro, participação parcial do proprietário e possibilidade de análise de elegibilidade migratória por especialista.",
      category: "business", asset_type: "restaurant_food", strategy: "renda_imediata", city: "Orange County", state: "FL",
      price_cents: 650_000_00, investment_min_cents: 650_000_00, current_income_cents: 75_000_00,
      projected_income_cents: 75_000_00, annual_profit_cents: 75_000_00, owner_salary_annual_cents: 18_000_00,
      owner_time_in_business_years: 4, owner_involvement: "part_time", franchise: true,
      sale_reason: "Saúde na família", visa_eligibility: "potentially_eligible", sector: "Comércio",
      ebitda_annual_cents: 75_000_00, ebitda_margin: 11.538, operating_model: "Operação ativa",
      investor_participation: 100, financing_available: true, market_status: "active", card_level: 2,
      business_details: { "brand" => "Restaurants & Food", "seller_financing" => true, "visa_note" => "Sujeito a análise jurídica e migratória especializada." },
      highlights: [ "Negócio em operação", "Localização em Orange County", "Seller financing disponível" ],
      risks: [ "Dependência da operação e da equipe", "Validação financeira e jurídica necessária" ], expert_curated: true
    }
  ].each_with_index do |attributes, index|
    card = InvestmentCard.find_or_initialize_by(slug: attributes[:slug])
    card.assign_attributes(attributes.merge(
      card_level: attributes.fetch(:card_level, 2), status: "draft", visibility: "private", featured: true, expert_curated: attributes.fetch(:expert_curated, false),
      curated_by: admin, source_name: "Florida Investments Research", verified_at: Time.current,
      alt_text: attributes[:title], disclaimer: "Material exclusivamente informativo; não constitui recomendação de investimento.",
      due_diligence: { "status" => "preliminary", "summary" => "Análise preliminar para demonstração." },
      financing: { "type" => "available", "ltv" => 75, "term_years" => 30 }, tags: [ "demo", "florida", attributes[:category] ],
      category_taxonomy: TaxonomyTerm.find_by!(kind: "category", slug: attributes[:category]),
      asset_type_taxonomy: TaxonomyTerm.find_by!(kind: "asset_type", slug: attributes[:asset_type]),
      strategy_taxonomy: TaxonomyTerm.find_by!(kind: "strategy", slug: attributes[:strategy]),
      market_taxonomy: TaxonomyTerm.find_by!(kind: "market", slug: attributes[:city].downcase.tr(" ", "_")),
      assumptions: "Os números dependem de validação financeira, inspeção e condições de mercado.",
      market_context: "Mercado com demanda consistente, sujeito a variações locais de oferta e crédito.",
      investment_profile: "Investidor com horizonte de médio a longo prazo e foco em diversificação.",
      return_strategy: "Renda operacional combinada a valorização do ativo.",
      expert_curated_reason: "Ativo selecionado após análise preliminar de localização, retorno e execução.",
      expert_curated_analysis: "Revisão inicial de dados operacionais, mercado e riscos disponíveis."
    ))
    card.save!
    image_path = attributes[:category] == "business" ? business_demo_image : (demo_images[index] || demo_images.first)
    if image_path && !card.cover_image.attached?
      card.cover_image.attach(io: File.open(image_path), filename: "#{card.slug}.webp", content_type: "image/webp")
    end
    if card.investment_card_metrics.empty?
      if card.cap_rate_projected.present?
        card.investment_card_metrics.create!(
          taxonomy_term: TaxonomyTerm.find_by!(kind: "metric_type", slug: "percentage"),
          label: "Cap rate projetado", value: card.cap_rate_projected.to_s, unit: "%", featured: true
        )
      end
      card.investment_card_metrics.create!(
        taxonomy_term: TaxonomyTerm.find_by!(kind: "metric_type", slug: "currency"),
        label: "Renda projetada anual", value: card.projected_income_cents.to_s, unit: "cents", featured: true
      )
    end
  end

  template = NewsletterTemplate.find_or_initialize_by(name: "Florida Editorial Demo")
  template.assign_attributes(
    status: "active", default_template: true,
    branding: { "primary_color" => "#0B1D3A", "header_text" => "Oportunidades selecionadas", "footer_text" => "Florida Investments | Descadastrar-se" },
    blocks: [
      { "id" => "demo-hero", "type" => "hero", "title" => "Novas oportunidades na Flórida", "content" => "Curadoria, dados e estratégia para investir melhor." },
      { "id" => "demo-text", "type" => "text", "title" => "Destaque da semana", "content" => "Conheça ativos selecionados pela nossa equipe." },
      { "id" => "demo-cta", "type" => "cta", "title" => "Fale com um especialista", "content" => "Receba uma análise alinhada ao seu perfil.", "button_label" => "Agendar conversa", "button_url" => "https://example.com/contact" }
    ]
  )
  template.save!

  content = NewsletterContent.find_or_initialize_by(slug: "demo-market-insights")
  content.assign_attributes(
    title: "Panorama do mercado: tendências da Flórida", content_type: "article", category: "market",
    status: "draft", subtitle: "Análises e perspectivas para investidores.",
    description: "Dados e sinais de mercado para apoiar decisões mais informadas.",
    alt_text: "Panorama do mercado imobiliário da Flórida", tags: [ "demo", "market" ]
  )
  content.save!

  report = MarketReport.find_or_initialize_by(slug: "florida-market-report-demo")
  report.assign_attributes(
    title: "Relatório do mercado imobiliário da Flórida", period: "2026 Q3", status: "draft", visibility: "private",
    excerpt: "Indicadores e tendências para acompanhar o mercado imobiliário da Flórida.",
    body: "Uma visão inicial de demanda, renda e oportunidades por região.",
    metrics: { "vacancy_rate" => 6.1, "average_cap_rate" => 6.4, "annual_rent_growth" => 3.8 },
    market_name: "Flórida", region: "Central Florida", source_name: nil,
    source_url: nil, seo_title: "Relatório do mercado imobiliário da Flórida | Florida Investments",
    seo_description: "Indicadores e tendências do mercado imobiliário da Flórida."
  )
  report.save!
  if report.market_report_metrics.empty?
    report.market_report_metrics.create!(taxonomy_term: TaxonomyTerm.find_by!(kind: "metric_type", slug: "percentage"), label: "Vacância", value: "6.1", unit: "%", variation: "-0,3 p.p.", featured: true)
    report.market_report_metrics.create!(taxonomy_term: TaxonomyTerm.find_by!(kind: "metric_type", slug: "percentage"), label: "Cap rate médio", value: "6.4", unit: "%", variation: "+0,2 p.p.", featured: true)
    report.market_report_metrics.create!(taxonomy_term: TaxonomyTerm.find_by!(kind: "metric_type", slug: "percentage"), label: "Crescimento anual de aluguel", value: "3.8", unit: "%", variation: "+0,4 p.p.")
  end

  page = ContentPage.find_or_initialize_by(slug: "about-demo")
  page.assign_attributes(
    title: "Sobre a Florida Investments", page_type: "institutional", eyebrow: "INSTITUCIONAL",
    excerpt: "Inteligência, curadoria e estratégia para investir com confiança.",
    body: "Conectamos investidores a oportunidades imobiliárias selecionadas com análise de mercado, disciplina e acompanhamento especializado.",
    template_key: "institutional", seo_title: "Sobre a Florida Investments", seo_description: "Conheça a metodologia da Florida Investments.",
    content_blocks: [
      { "type" => "hero", "title" => "Inteligência, curadoria e estratégia", "content" => "Para investir com confiança na Flórida." },
      { "type" => "text", "title" => "Nossa metodologia", "content" => "Mapeamento, triagem, análise aprofundada, validação e acompanhamento." }
    ], status: "draft", visibility: "private", metadata: { "demo" => true, "content_locale" => "pt-BR" }
  )
  page.save!

  {
    "home-demo" => {
      title: "Florida Investments",
      eyebrow: "OPORTUNIDADES SELECIONADAS",
      excerpt: "Inteligência de mercado e curadoria para investir na Flórida.",
      body: "Conteúdo institucional editável pela equipe, com chamadas e blocos estruturados para a página inicial.",
      template_key: "home",
      content_blocks: [
        { "type" => "hero", "title" => "As melhores oportunidades não aparecem por acaso.", "content" => "São selecionadas com dados, análise e estratégia.", "button_label" => "Explorar oportunidades", "button_url" => "/opportunities" },
        { "type" => "cta", "title" => "Vamos encontrar a oportunidade certa para você.", "content" => "Receba uma orientação alinhada ao seu perfil.", "button_label" => "Agendar conversa", "button_url" => "/contact" }
      ]
    },
    "methodology-demo" => {
      title: "Metodologia de seleção",
      eyebrow: "EXPERT CURATED",
      excerpt: "Uma seleção baseada em inteligência de mercado e validação local.",
      body: "Mapeamento, triagem, análise aprofundada, validação local, seleção e acompanhamento.",
      template_key: "institutional",
      content_blocks: [
        { "type" => "text", "title" => "Como selecionamos", "content" => "Análise financeira, operacional, de risco e aderência à estratégia de cada investidor." }
      ]
    },
    "founder-demo" => {
      title: "Fundador e credibilidade",
      eyebrow: "FLORIDA INVESTMENTS",
      excerpt: "Experiência local para orientar decisões mais seguras.",
      body: "Uma página editável para apresentar liderança, histórico e princípios da operação.",
      template_key: "institutional",
      content_blocks: [
        { "type" => "text", "title" => "Nossa liderança", "content" => "Histórico, especialidades e experiência são administrados diretamente neste bloco." }
      ]
    },
    "partners-demo" => {
      title: "Ecossistema de parceiros",
      eyebrow: "PARCEIROS",
      excerpt: "Profissionais que apoiam cada etapa da jornada de investimento.",
      body: "Apresente parceiros, serviços e links oficiais com blocos estruturados.",
      template_key: "institutional",
      content_blocks: [
        { "type" => "cta", "title" => "Fale com nossa equipe", "content" => "Conheça a rede de suporte para a sua estratégia.", "button_label" => "Entrar em contato", "button_url" => "/contact" }
      ]
    },
    "services-demo" => {
      title: "Serviços e acompanhamento",
      eyebrow: "ACOMPANHAMENTO",
      excerpt: "Apoio especializado da seleção à integração do ativo.",
      body: "Estruture a apresentação de serviços, escopo e chamadas de contato sem depender de uma alteração no código.",
      template_key: "institutional",
      content_blocks: [
        { "type" => "text", "title" => "Análise e acompanhamento", "content" => "Curadoria, due diligence e orientação estratégica em cada etapa." },
        { "type" => "cta", "title" => "Converse com um especialista", "content" => "Conte para nós seus objetivos de investimento.", "button_label" => "Agendar conversa", "button_url" => "/contact" }
      ]
    },
    "investor-information-demo" => {
      title: "Informações ao investidor",
      eyebrow: "INFORMAÇÕES IMPORTANTES",
      excerpt: "Conteúdo informativo para apoiar uma tomada de decisão consciente.",
      body: "A operação não substitui assessoria jurídica, tributária, financeira ou a decisão final do investidor.",
      template_key: "institutional",
      content_blocks: [
        { "type" => "text", "title" => "Aviso ao investidor", "content" => "Rentabilidade passada não representa garantia de resultados futuros." },
        { "type" => "cta", "title" => "Veja oportunidades selecionadas", "content" => "Explore os ativos publicados e suas informações disponíveis.", "button_label" => "Ver oportunidades", "button_url" => "/opportunities" }
      ]
    }
  }.each do |slug, attributes|
    managed_page = ContentPage.find_or_initialize_by(slug:)
    managed_page.assign_attributes(attributes.merge(
      page_type: "institutional", status: "draft", visibility: "private",
      seo_title: attributes[:title], seo_description: attributes[:excerpt], metadata: { "demo" => true, "content_locale" => "pt-BR" }
    ))
    managed_page.save!
  end

  %w[investor@example.com partner@example.com].each do |email|
    NewsletterSubscriber.find_or_create_by!(email:) { |subscriber| subscriber.source = "demo" }
  end

  edition = NewsletterEdition.find_or_initialize_by(slug: "demo-market-insights-april")
  edition.assign_attributes(
    title: "Panorama do mercado: abril", excerpt: "Tendências e oportunidades selecionadas para você.", status: "draft", visibility: "private",
    edition_date: Date.new(2026, 4, 15), cta_label: "Ver oportunidades", cta_url: "/opportunities",
    seo_title: "Panorama do mercado: abril", seo_description: "Tendências e oportunidades selecionadas para investidores.",
    metadata: { "content_locale" => "pt-BR", "subject" => "Panorama do mercado: abril", "preheader" => "Novidades selecionadas pela Florida Investments.", "template_id" => template.id,
                "blocks" => template.blocks, "branding" => template.branding }
  )
  edition.save!
  if demo_images.first && !edition.cover_image.attached?
    edition.cover_image.attach(io: File.open(demo_images.first), filename: "market-insights-april.webp", content_type: "image/webp")
  end
  puts "Seeded development demo content"
end
