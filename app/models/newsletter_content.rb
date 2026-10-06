class NewsletterContent < ApplicationRecord
  include Discard::Model
  has_many_attached :images
  has_many_attached :documents
  belongs_to :investment_card, optional: true
  enum :content_type, { property: "property", article: "article", event: "event", banner: "banner", cta: "cta", testimonial: "testimonial" }, validate: true
  enum :status, { draft: "draft", published: "published", archived: "archived" }, default: :draft, validate: true
  validates :title, :content_type, presence: true
  validates :slug, uniqueness: true, allow_blank: true
  validates :cta_url, :registration_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
  validates :cta_target, inclusion: { in: %w[_self _blank] }
  validates :tracking_key, format: { with: /\A[a-zA-Z0-9._-]+\z/ }, allow_blank: true
  validate :validate_content_type_fields
  validates :event_date, :event_time, :event_timezone, presence: true, if: :event?
  scope :available, -> { kept.where.not(status: :archived).order(updated_at: :desc) }
  scope :favorites, -> { where(favorite: true) }
  scope :recently_used, -> { where.not(last_used_at: nil).order(last_used_at: :desc) }

  private

  def validate_content_type_fields
    if cta? && cta_label.blank?
      errors.add(:cta_label, "is required for CTA items")
    end

    errors.add(:cta_url, "is required for CTA items") if cta? && cta_url.blank?
  end
end
