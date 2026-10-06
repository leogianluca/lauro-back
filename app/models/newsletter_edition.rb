class NewsletterEdition < ApplicationRecord
  include Discard::Model
  extend FriendlyId

  friendly_id :title, use: :slugged

  has_many_attached :images
  has_many_attached :documents
  has_one_attached :cover_image
  has_one_attached :seo_image
  has_many :media_import_batches, dependent: :restrict_with_exception
  has_many :newsletter_deliveries, dependent: :restrict_with_exception
  has_many :newsletter_edition_segments, dependent: :destroy
  has_many :newsletter_segments, through: :newsletter_edition_segments
  has_many :newsletter_edition_versions, dependent: :destroy
  has_many :newsletter_approval_comments, dependent: :destroy
  has_many :newsletter_metric_events, dependent: :destroy

  enum :status, {
    draft: "draft",
    in_review: "in_review",
    awaiting_approval: "awaiting_approval",
    approved: "approved",
    scheduled: "scheduled",
    sending: "sending",
    sent: "sent",
    error: "error",
    published: "published",
    archived: "archived"
  }, default: :draft, validate: true

  enum :visibility, {
    public: "public",
    private: "private"
  }, prefix: true, default: :public, validate: true

  before_validation :set_published_at, if: :published?

  validates :title, :slug, :status, :visibility, presence: true
  validates :slug, uniqueness: true
  validates :body, presence: true, if: :published?

  scope :publicly_visible, -> { where(visibility: :public) }
  scope :published_for_public, -> { published.kept.publicly_visible.order(published_at: :desc, created_at: :desc) }

  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def schedule!(at)
    update!(status: :scheduled, published_at: at, metadata: metadata.merge("scheduled_at" => at.iso8601))
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
end
