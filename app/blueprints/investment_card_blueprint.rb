class InvestmentCardBlueprint < Blueprinter::Base
  identifier :id

  view :card do
    fields :title, :slug, :summary, :category, :asset_type, :strategy, :city,
           :state, :region, :country, :status, :visibility, :card_level, :featured,
           :expert_curated, :price_cents, :price_currency,
           :investment_min_cents, :investment_max_cents, :address_line1, :address_line2,
           :zip_code, :latitude, :longitude, :current_income_cents, :projected_income_cents,
           :investment_broker_id, :investment_company_id, :investment_location_id,
           :noi_current_cents, :noi_projected_cents, :cap_rate_current, :cap_rate_projected,
           :cash_on_cash, :occupancy_rate, :gross_yield_percent, :hpi_10_year_percent,
           :estimated_months, :sector, :ebitda_annual_cents,
           :ebitda_margin, :operating_model, :investor_participation, :investment_thesis,
           :annual_profit_cents, :owner_salary_annual_cents, :owner_time_in_business_years,
           :owner_involvement, :franchise, :sale_reason, :visa_eligibility, :business_details,
           :market_status, :down_payment_percent, :down_payment_cents, :living_area_sqft,
           :bedrooms, :bathrooms, :year_built, :estimated_roi_min, :estimated_roi_max,
           :equity_generated_min_cents, :equity_generated_max_cents, :financing_available,
           :quota_available, :property_details,
           :assumptions, :market_context, :investment_profile, :return_strategy,
           :expert_curated_reason, :expert_curated_analysis, :seo_title, :seo_description,
           :category_taxonomy_id, :asset_type_taxonomy_id, :strategy_taxonomy_id, :market_taxonomy_id,
           :highlights, :risks, :tags, :due_diligence, :financing, :alt_text, :source_name, :verified_at,
           :curated_by_id, :disclaimer
  field :cover_image_url do |card|
      card.cover_image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(card.cover_image, host: ENV.fetch("APP_PUBLIC_URL", "http://localhost:3000")) : nil
    end
  end

  field :investment_broker do |card|
    card.investment_broker&.as_json(only: %i[id name company_name])
  end
  field :investment_company do |card|
    card.investment_company&.as_json(only: %i[id name sector])
  end
  field :investment_location do |card|
    card.investment_location&.as_json(only: %i[id name city state country])
  end

  field :taxonomies do |card|
    {
      category: card.category_taxonomy&.slice(:id, :name, :slug),
      asset_type: card.asset_type_taxonomy&.slice(:id, :name, :slug),
      strategy: card.strategy_taxonomy&.slice(:id, :name, :slug),
      market: card.market_taxonomy&.slice(:id, :name, :slug)
    }.compact
  end

  view :detail do
    include_view :card

    fields :description, :source_url, :external_reference, :metadata,
           :published_at, :created_at, :updated_at, :cover_image_attached,
           :gallery_images_count, :documents_count
    field :metrics do |card|
      InvestmentCardMetricBlueprint.render_as_hash(card.investment_card_metrics)
    end
    field :gallery_items do |card|
      InvestmentCardMediumBlueprint.render_as_hash(card.investment_card_media)
    end
    field :documents do |card|
      card.documents.attachments.map do |attachment|
        {
          id: attachment.id,
          filename: attachment.filename.to_s,
          content_type: attachment.content_type,
          byte_size: attachment.byte_size,
          public_url: card.published? && card.visibility == "public" ? "/api/v1/investment_cards/#{card.slug}/documents/#{attachment.id}" : nil,
          admin_url: "/api/v1/admin/investment_cards/#{card.id}/documents/#{attachment.id}"
        }
      end
    end
    field :seo_image_url do |card|
      next unless card.seo_image.attached?

      Rails.application.routes.url_helpers.rails_blob_url(card.seo_image, host: ENV.fetch("APP_PUBLIC_URL", "http://localhost:3000"))
    end
    field :gallery_image_urls do |card|
      card.gallery_images.attachments.map { |attachment| Rails.application.routes.url_helpers.rails_blob_url(attachment, host: ENV.fetch("APP_PUBLIC_URL", "http://localhost:3000")) }
    end
  end
end
