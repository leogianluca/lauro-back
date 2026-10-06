class NewsletterDelivery < ApplicationRecord
  MAX_ATTEMPTS = 3

  belongs_to :newsletter_edition
  belongs_to :newsletter_subscriber
  has_many :newsletter_metric_events, dependent: :destroy

  enum :status, {
    queued: "queued",
    sent: "sent",
    failed: "failed"
  }, default: :queued, validate: true

  validates :newsletter_subscriber_id, uniqueness: { scope: :newsletter_edition_id }
  validates :attempts, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_ATTEMPTS }

  scope :retryable, -> { failed.where("attempts < ?", MAX_ATTEMPTS) }
end
