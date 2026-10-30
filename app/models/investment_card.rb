class InvestmentCard < ApplicationRecord
  include Discard::Model
  extend FriendlyId

  friendly_id :title, use: :slugged

  has_one_attached :cover_image
  has_many_attached :gallery_images
  has_many_attached :documents
  has_one_attached :seo_image
  has_many :media_import_batches, dependent: :restrict_with_exception
  has_many :favorites, dependent: :destroy
  has_many :investment_card_metrics, -> { order(:position) }, dependent: :destroy
  has_many :investment_card_media, -> { order(:position) }, dependent: :destroy
  belongs_to :curated_by, class_name: "User", optional: true
  belongs_to :investment_broker, optional: true
  belongs_to :investment_company, optional: true
  belongs_to :investment_location, optional: true
  belongs_to :category_taxonomy, class_name: "TaxonomyTerm", optional: true
  belongs_to :asset_type_taxonomy, class_name: "TaxonomyTerm", optional: true
  belongs_to :strategy_taxonomy, class_name: "TaxonomyTerm", optional: true
  belongs_to :market_taxonomy, class_name: "TaxonomyTerm", optional: true
  accepts_nested_attributes_for :investment_broker, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :investment_company, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :investment_location, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :investment_card_metrics, allow_destroy: true, reject_if: :all_blank

  enum :status, {
    draft: "draft",
    published: "published",
    archived: "archived"
  }, default: :draft, validate: true

  enum :visibility, {
    public: "public",
    private: "private"
  }, prefix: true, default: :public, validate: true

  enum :market_status, {
    active: "active",
    pending: "pending",
    closed: "closed",
    off_market: "off_market"
  }, prefix: true, default: :active, validate: true

  before_validation :set_published_at, if: :published?

  validates :title, :status, :visibility, :card_level, :category, :strategy, presence: true
  validate :location_is_present
  validates :slug, uniqueness: true
  validates :card_level, inclusion: { in: 1..2 }
  validates :price_currency, presence: true
  validates :living_area_sqft, :bedrooms, :year_built, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :bathrooms, :estimated_roi_min, :estimated_roi_max, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :gross_yield_percent, :hpi_10_year_percent, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price_cents, :investment_min_cents, :investment_max_cents, :down_payment_cents,
            :current_income_cents, :projected_income_cents, :noi_current_cents, :noi_projected_cents,
            :ebitda_annual_cents, :annual_profit_cents, :owner_salary_annual_cents,
            :equity_generated_min_cents, :equity_generated_max_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :down_payment_percent, :occupancy_rate, :ebitda_margin, :investor_participation,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :owner_time_in_business_years, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :published_data_is_complete, if: :published?
  validate :financing_simulation_is_valid
  validate :residential_featured_limit
  validate :structured_metadata_has_expected_shape
  validate :taxonomy_terms_match_expected_kinds

  scope :published, -> { where(status: :published) }
  scope :featured, -> { where(featured: true) }
  scope :expert_curated, -> { where(expert_curated: true) }
  scope :publicly_visible, -> { where(visibility: :public) }
  scope :ordered_for_public, -> { order(featured: :desc, featured_position: :asc, published_at: :desc, created_at: :desc) }

  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def archive!
    update!(status: :archived)
  end

  def hide!
    update!(visibility: :private)
  end

  def show!
    update!(visibility: :public)
  end

  def feature!(position: nil)
    update!(featured: true, featured_position: position || next_featured_position)
  end

  def unfeature!
    update!(featured: false, featured_position: nil)
  end

  def mark_expert_curated!
    update!(expert_curated: true)
  end

  def unmark_expert_curated!
    update!(expert_curated: false)
  end

  def cover_image_attached
    cover_image.attached?
  end

  def gallery_images_count
    gallery_images.attachments.size
  end

  def documents_count
    documents.attachments.size
  end

  def should_generate_new_friendly_id?
    slug.blank?
  end

  private

  def financing_simulation_is_valid
    return unless %w[commercial comercial].include?(category.to_s.downcase) && financing.is_a?(Hash)

    rate = financing["interest_rate_percent"]
    term = financing["term_years"]
    down = financing["down_payment_cents"]
    if !rate.nil? && rate != "" && !(rate.is_a?(Numeric) && rate.finite? && rate.between?(0, 100))
      errors.add(:financing, "annual interest must be between 0 and 100 percent")
    end
    if !term.nil? && term != "" && !(term.is_a?(Integer) && term.between?(1, 50))
      errors.add(:financing, "amortization term must be a whole number from 1 to 50 years")
    end
    if !down.nil? && down != "" && !(down.is_a?(Integer) && down.between?(0, 9_007_199_254_740_991) && (price_cents.nil? || down <= price_cents))
      errors.add(:financing, "down payment must be integer cents between zero and the price")
    end
  end

  def location_is_present
    if %w[empresa empresas business].include?(category.to_s.downcase)
      errors.add(:region, "or city and state is required") if region.blank? && (city.blank? || state.blank?)
    else
      errors.add(:city, "is required") if city.blank?
      errors.add(:state, "is required") if state.blank?
    end
  end

  def set_published_at
    self.published_at ||= Time.current
  end

  def published_data_is_complete
    business_card = %w[empresa empresas business].include?(category.to_s.downcase)
    errors.add(:summary, "is required before publication") if summary.blank? && !business_card
    errors.add(:price_cents, "must be greater than zero before publication") if price_cents.blank? || price_cents <= 0
    errors.add(:alt_text, "is required before publication") if alt_text.blank? && !business_card
    errors.add(:disclaimer, "is required before publication") if disclaimer.blank? && !business_card
    errors.add(:cover_image, "is required before publication") unless cover_image.attached?
    if business_card
      errors.add(:sector, "is required for business cards") if sector.blank?
    end
    if %w[build_to_sell build_to_rent development].include?(strategy.to_s.downcase)
      errors.add(:estimated_months, "is required for development strategies") if estimated_months.blank?
    end
    if expert_curated?
      errors.add(:curated_by_id, "is required for Expert Curated cards") if curated_by_id.blank?
      errors.add(:source_name, "is required for Expert Curated cards") if source_name.blank?
      errors.add(:verified_at, "is required for Expert Curated cards") if verified_at.blank?
      errors.add(:expert_curated_reason, "is required for Expert Curated cards") if expert_curated_reason.blank?
    end
    if card_level.to_i >= 2
      errors.add(:market_status, "is required for level 2 cards") if market_status.blank?
    end
    if residential_level_two?
      if residential_land?
        area = property_details.is_a?(Hash) && (property_details["total_acreage"] || property_details["total_area"])
        errors.add(:property_details, "must include land area for level 2 land cards") if area.blank?
      else
        errors.add(:living_area_sqft, "is required for level 2 cards") if living_area_sqft.blank?
        errors.add(:bedrooms, "is required for level 2 cards") if bedrooms.blank?
        errors.add(:bathrooms, "is required for level 2 cards") if bathrooms.blank?
        unless %w[build_to_sell build_to_rent development].include?(strategy.to_s.downcase)
          errors.add(:year_built, "is required for level 2 cards") if year_built.blank?
        end
      end
    end
    if business_level_two?
      sde = business_details.is_a?(Hash) && business_details["sde_annual_cents"]
      errors.add(:business_details, "must include adjusted profit (SDE) for business level 2 cards") unless sde.is_a?(Integer) && sde >= 0
      if business_details.is_a?(Hash) && (business_details["segment"].blank? || business_details["segment"] == "other") && business_details["strategy_badge"].blank?
        errors.add(:business_details, "must include a business subtype")
      end
      errors.add(:sector, "is required for business level 2 cards") if sector.blank?
      errors.add(:owner_involvement, "is required for business level 2 cards") if owner_involvement.blank?
    end
  end

  def residential_featured_limit
    return unless featured? && published? && visibility_public? && %w[residential residencial residencials].include?(category.to_s.downcase)
    return if persisted? && featured_in_database? && status_in_database == status && visibility_in_database == visibility && category_in_database == category

    selected = self.class.kept.where(status: "published", visibility: "public", featured: true)
      .where("LOWER(category) IN (?)", %w[residential residencial residencials])
    selected = selected.where.not(id: id) if persisted?
    errors.add(:featured, "allows at most three published residential opportunities") if selected.count >= 3
  end

  def next_featured_position
    self.class.where(featured: true).maximum(:featured_position).to_i + 1
  end

  def residential_level_two?
    card_level.to_i >= 2 && category.to_s.downcase == "residential"
  end

  def residential_land?
    %w[land terreno].include?(asset_type.to_s.downcase)
  end

  def business_level_two?
    card_level.to_i >= 2 && %w[business empresa empresas].include?(category.to_s.downcase)
  end

  def structured_metadata_has_expected_shape
    %i[highlights risks tags].each do |field|
      value = public_send(field)
      errors.add(field, "must be a list of text values") unless value.is_a?(Array) && value.all? { |item| item.is_a?(String) }
    end

    %i[due_diligence financing].each do |field|
      errors.add(field, "must be an object") unless public_send(field).is_a?(Hash)
    end
    errors.add(:property_details, "must be an object") unless property_details.is_a?(Hash)
    errors.add(:business_details, "must be an object") unless business_details.is_a?(Hash)
  end

  def taxonomy_terms_match_expected_kinds
    {
      category_taxonomy: [ "category", :category ],
      asset_type_taxonomy: [ "asset_type", :asset_type ],
      strategy_taxonomy: [ "strategy", :strategy ],
      market_taxonomy: [ "market", nil ]
    }.each do |association, (expected_kind, legacy_attribute)|
      term = public_send(association)
      next unless term

      errors.add(association, "must be a #{expected_kind}") if term.kind != expected_kind
      errors.add(legacy_attribute, "must match the selected taxonomy") if legacy_attribute && term.kind == expected_kind && public_send(legacy_attribute) != term.slug
    end
  end
end
