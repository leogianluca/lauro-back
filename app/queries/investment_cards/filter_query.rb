module InvestmentCards
  class FilterQuery
    SORTS = {
      "recent" => { published_at: :desc, created_at: :desc, id: :asc },
      "oldest" => { published_at: :asc, created_at: :asc, id: :asc },
      "price_asc" => { price_cents: :asc, id: :asc },
      "price_desc" => { price_cents: :desc, id: :asc },
      "featured" => { featured: :desc, featured_position: :asc, published_at: :desc, created_at: :desc, id: :asc }
    }.freeze

    def initialize(scope, params)
      @scope = scope
      @params = params
    end

    def call
      result = @scope
      result = result.where(id: requested_ids) if requested_ids.any?
      result = result.where(status: @params[:status]) if present?(:status)
      result = result.where(category: @params[:category]) if present?(:category)
      result = result.where(asset_type: @params[:asset_type]) if present?(:asset_type)
      result = result.where(strategy: @params[:strategy]) if present?(:strategy)
      result = result.where("city ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(@params[:city].to_s.strip)}%") if present?(:city)
      result = result.where(state: @params[:state]) if present?(:state)
      result = result.where(region: @params[:region]) if present?(:region)
      result = result.where(expert_curated: boolean_value(:expert_curated)) if boolean_value(:expert_curated).in?([ true, false ])
      result = result.where(featured: boolean_value(:featured)) if boolean_value(:featured).in?([ true, false ])
      result = result.where("price_cents >= ?", @params[:min_price_cents].to_i) if present?(:min_price_cents)
      result = result.where("price_cents <= ?", @params[:max_price_cents].to_i) if present?(:max_price_cents)
      result = result.where("title ILIKE :query OR summary ILIKE :query", query: "%#{escaped_query}%") if present?(:q)
      result.reorder(SORTS.fetch(@params[:sort].to_s, SORTS["featured"]))
    end

    private

    def present?(key)
      @params[key].present?
    end

    def boolean_value(key)
      ActiveModel::Type::Boolean.new.cast(@params[key])
    end

    def escaped_query
      ActiveRecord::Base.sanitize_sql_like(@params[:q].to_s)
    end

    def requested_ids
      @requested_ids ||= begin
        raw_ids = @params[:ids]
        values = raw_ids.is_a?(Array) ? raw_ids : raw_ids.to_s.split(",")
        values.map { |id| id.to_s.strip }.reject(&:blank?).uniq.first(10_000)
      end
    end
  end
end
