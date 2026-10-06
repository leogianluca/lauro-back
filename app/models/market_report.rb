class MarketReport < ApplicationRecord
  include Discard::Model
  extend FriendlyId

  friendly_id :title, use: :slugged

  has_many_attached :documents
  has_many_attached :images
  has_one_attached :seo_image
  has_many :market_report_metrics, -> { order(:position) }, dependent: :destroy

  accepts_nested_attributes_for :market_report_metrics, allow_destroy: true, reject_if: :all_blank

  enum :status, {
    draft: "draft",
    published: "published",
    archived: "archived"
  }, default: :draft, validate: true

  enum :visibility, {
    public: "public",
    private: "private"
  }, prefix: true, default: :public, validate: true

  before_validation :set_published_at, if: :published?

  validates :title, :slug, :period, :status, :visibility, presence: true
  validates :slug, uniqueness: true
  validates :period, format: { with: /\A\d{4}-(0[1-9]|1[0-2])\z/ }, if: :published?
  validates :body, presence: true, if: :published?
  validates :source_name, presence: true, if: :published_with_metrics?

  scope :published_for_public, -> { published.kept.where(visibility: :public).order(period: :desc, published_at: :desc) }

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

  def should_generate_new_friendly_id?
    slug.blank?
  end

  private

  def set_published_at
    self.published_at ||= Time.current
  end

  def published_with_metrics?
    published? && (metrics.present? || market_report_metrics.any?)
  end
end
