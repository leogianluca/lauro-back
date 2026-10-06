class NewsletterMetricEvent < ApplicationRecord
  belongs_to :newsletter_edition
  belongs_to :newsletter_delivery, optional: true
  validates :event_type, :occurred_at, presence: true
  validates :idempotency_key, uniqueness: true, allow_blank: true
end
