class TaxonomyTerm < ApplicationRecord
  include Discard::Model

  KINDS = %w[category asset_type strategy market tag market_status metric_type].freeze

  belongs_to :parent, class_name: "TaxonomyTerm", optional: true
  has_many :children, class_name: "TaxonomyTerm", foreign_key: :parent_id, dependent: :restrict_with_exception

  validates :kind, inclusion: { in: KINDS }
  validates :name, :slug, presence: true
  validates :slug, uniqueness: { scope: :kind }

  scope :active, -> { kept.where(active: true) }
  scope :ordered, -> { order(:position, :name) }
end
