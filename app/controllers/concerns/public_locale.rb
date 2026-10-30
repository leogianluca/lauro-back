module PublicLocale
  SUPPORTED_LOCALES = %w[pt-BR en es].freeze
  TRANSLATED_FIELDS = {
    "ContentPage" => %i[title eyebrow excerpt body content_blocks],
    "MarketReport" => %i[title excerpt body],
    "NewsletterEdition" => %i[title excerpt body cta_label]
  }.freeze
  PUBLIC_PROPERTY_DETAIL_FIELDS = %i[
    property_style lp_per_sqft can_be_leased new_construction pool minimum_lease_period
    heated_area garage pets total_area garage_spaces special_sale total_acreage subdivision
    subtype subtype_label strategy_badge feature_badge asset_badge term_label
    unit_count year_renovated zoning ownership area property_class building_count floor_count
    parking_spaces price_per_sqft net_rentable_area_sqft lease_type ground_lease
    offering_memorandum rent_bumps lease_expiration remaining_term ceiling_height_ft
    loading_docks dock_height_ft parking_per_1000_sqft stabilized_yield_on_cost
  ].freeze
  PUBLIC_BUSINESS_DETAIL_FIELDS = %i[
    badge segment strategy_badge visa_program time_in_business sde_annual_cents
  ].freeze

  private

  def public_locale
    requested = params[:locale].to_s
    SUPPORTED_LOCALES.include?(requested) ? requested : "pt-BR"
  end

  def localize_public_record(record, payload)
    metadata = record.respond_to?(:metadata) && record.metadata.is_a?(Hash) ? record.metadata : {}
    base_locale = metadata["content_locale"].presence
    base_locale = "pt-BR" unless SUPPORTED_LOCALES.include?(base_locale)
    requested_locale = public_locale
    candidate = metadata.dig("translations", requested_locale)
    candidate_fields = if candidate.is_a?(Hash) && candidate["fields"].is_a?(Hash)
      candidate["fields"]
    else
      candidate
    end
    translation = if candidate.is_a?(Hash) && candidate["status"] == "published" && candidate["complete"] == true
      candidate_fields
    else
      {}
    end
    fields = TRANSLATED_FIELDS.fetch(record.class.name, [])
    localized_fields = translation.slice(*fields.map(&:to_s)).deep_symbolize_keys
    translation_complete = public_translation_complete?(record, payload.deep_symbolize_keys, fields, localized_fields)
    localized_fields = {} unless translation_complete
    content_locale = localized_fields.any? ? requested_locale : base_locale

    safe_payload = payload.deep_symbolize_keys.except(
      :metadata, :status, :visibility, :created_at, :updated_at, :external_reference,
      :curated_by_id, :address_line1, :address_line2, :zip_code, :latitude, :longitude,
      :investment_broker_id, :investment_company_id, :investment_location_id,
      :category_taxonomy_id, :asset_type_taxonomy_id, :strategy_taxonomy_id,
      :market_taxonomy_id, :seo_title, :seo_description, :admin_url, :source_name,
      :due_diligence
    )
    if record.is_a?(InvestmentCard)
      if %w[business empresa empresas].include?(record.category.to_s.downcase)
        safe_payload = safe_payload.except(
          :owner_salary_annual_cents, :annual_profit_cents, :ebitda_annual_cents,
          :ebitda_margin, :operating_model, :investor_participation
        )
      end
      unless record.market_status == "off_market"
        safe_payload = safe_payload.merge(payload.deep_symbolize_keys.slice(:address_line1, :address_line2, :zip_code))
      end
      if safe_payload[:business_details].is_a?(Hash)
        safe_payload[:business_details] = safe_payload[:business_details].slice(*PUBLIC_BUSINESS_DETAIL_FIELDS)
      end
      if safe_payload[:financing].is_a?(Hash)
        financing_fields = %w[commercial comercial].include?(record.category.to_s.downcase) ?
          %i[type ltv term_years interest_rate_percent down_payment_cents] : %i[type]
        safe_payload[:financing] = safe_payload[:financing].slice(*financing_fields)
      end
    else
      safe_payload = safe_payload.except(:business_details, :financing)
    end
    safe_payload = safe_payload.except(:investment_broker, :investment_company)
    if safe_payload[:investment_location].is_a?(Hash)
      safe_payload[:investment_location] = safe_payload[:investment_location].except(:id)
      if record.is_a?(InvestmentCard) && record.market_status == "off_market"
        safe_payload[:investment_location] = safe_payload[:investment_location].except(:name, :address_line1, :address_line2, :zip_code)
      end
    end
    if safe_payload[:taxonomies].is_a?(Hash)
      safe_payload[:taxonomies] = safe_payload[:taxonomies].transform_values do |taxonomy|
        taxonomy.is_a?(Hash) ? taxonomy.except(:id) : taxonomy
      end
    end
    if safe_payload[:property_details].is_a?(Hash)
      safe_payload[:property_details] = safe_payload[:property_details].slice(*PUBLIC_PROPERTY_DETAIL_FIELDS)
    end
    if localized_fields[:content_blocks].is_a?(Array) && safe_payload[:content_blocks].is_a?(Array)
      text_fields = %i[title content button_label alt_text caption]
      safe_payload[:content_blocks] = safe_payload[:content_blocks].zip(localized_fields[:content_blocks]).map do |source_block, translated_block|
        next source_block unless source_block.is_a?(Hash) && translated_block.is_a?(Hash)

        source_block.merge(translated_block.slice(*text_fields))
      end
      localized_fields = localized_fields.except(:content_blocks)
    end
    safe_payload = safe_payload.merge(localized_fields)
    if safe_payload[:content_blocks].is_a?(Array)
      safe_payload[:content_blocks] = safe_payload[:content_blocks].filter_map do |block|
        next unless block.is_a?(Hash)

        block.slice(:type, :title, :content, :button_label, :button_url, :image_url, :alt_text, :caption)
      end
    end
    if safe_payload[:documents].is_a?(Array)
      safe_payload[:documents] = safe_payload[:documents].map do |document|
        document.slice(:id, :filename, :content_type, :byte_size, :public_url)
      end
    end
    if safe_payload[:gallery_items].is_a?(Array)
      safe_payload[:gallery_items] = safe_payload[:gallery_items].map do |item|
        item.slice(:kind, :alt_text, :caption, :image_url)
      end
    end
    %i[metrics report_metrics].each do |key|
      next unless safe_payload[key].is_a?(Array)

      allowed_fields = key == :report_metrics ? %i[label value unit variation] : %i[label value unit]
      safe_payload[key] = safe_payload[key].map do |metric|
        metric.slice(*allowed_fields)
      end
    end

    safe_payload.merge(
      locale: {
        requested_locale: requested_locale,
        content_locale: content_locale,
        fallback_used: !record.is_a?(InvestmentCard) && requested_locale != content_locale
      }
    )
  end

  def public_translation_complete?(record, payload, fields, translation)
    return false if fields.empty? || translation.empty?

    required_fields = fields.filter_map do |field|
      source = record.respond_to?(field) ? record.public_send(field) : payload[field]
      [ field, source ] if translation_source_has_text?(source)
    end
    return false if required_fields.empty?

    required_fields.all? do |field, source|
      translated = translation[field]
      translation_value_complete?(field, source, translated)
    end
  end

  def translation_source_has_text?(value)
    case value
    when String then value.present?
    when Array then value.any? { |item| translation_source_has_text?(item) }
    else false
    end
  end

  def translation_value_complete?(field, source, translated)
    return translated.is_a?(String) && translated.present? if source.is_a?(String)
    return false unless source.is_a?(Array) && translated.is_a?(Array) && source.length == translated.length

    if field.to_s == "content_blocks"
      text_fields = %w[title content button_label alt_text caption]
      return source.zip(translated).all? do |source_block, translated_block|
        next false unless source_block.is_a?(Hash) && translated_block.is_a?(Hash)

        text_fields.all? do |key|
          source_text = source_block[key].presence
          source_text.nil? || translated_block[key].is_a?(String) && translated_block[key].present?
        end
      end
    end

    source.zip(translated).all? do |source_item, translated_item|
      !translation_source_has_text?(source_item) || translated_item.is_a?(String) && translated_item.present?
    end
  end

  def public_locale_meta(localized_records)
    records = Array(localized_records)
    fallback_count = records.count { |record| record.dig(:locale, :fallback_used) }
    {
      locale: {
        requested_locale: public_locale,
        fallback_count: fallback_count,
        fallback_used: records.any? { |record| record.dig(:locale, :fallback_used) }
      }
    }
  end
end
