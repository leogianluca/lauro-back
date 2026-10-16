class TaxonomyTerm < ApplicationRecord
  include Discard::Model

  KINDS = %w[category asset_type strategy market tag market_status metric_type].freeze

  belongs_to :parent, class_name: "TaxonomyTerm", optional: true
  has_many :children, class_name: "TaxonomyTerm", foreign_key: :parent_id, dependent: :restrict_with_exception

  validates :kind, inclusion: { in: KINDS }
  validates :name, :slug, presence: true
  validates :slug, uniqueness: { scope: :kind }
  validate :keep_identifier_when_used, on: :update

  scope :active, -> { kept.where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  def used?
    InvestmentCard.where(category_taxonomy_id: id).exists? ||
      InvestmentCard.where(asset_type_taxonomy_id: id).exists? ||
      InvestmentCard.where(strategy_taxonomy_id: id).exists? ||
      InvestmentCard.where(market_taxonomy_id: id).exists? ||
      InvestmentCardMetric.where(taxonomy_term_id: id).exists? ||
      MarketReportMetric.where(taxonomy_term_id: id).exists? ||
      children.exists?
  end

  private

  def keep_identifier_when_used
    return unless used? && (will_save_change_to_slug? || will_save_change_to_kind?)

    errors.add(:base, "A classificação já está em uso. Altere apenas o nome, a descrição ou a disponibilidade.")
  end
end
