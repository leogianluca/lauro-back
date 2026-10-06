class NewsletterSubscriber < ApplicationRecord
  has_many :newsletter_deliveries, dependent: :restrict_with_exception
  has_many :newsletter_metric_events, through: :newsletter_deliveries

  enum :status, {
    subscribed: "subscribed",
    unsubscribed: "unsubscribed"
  }, default: :subscribed, validate: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: true
  before_validation :normalize_email

  def subscribe!
    now = Time.current
    update!(status: :subscribed, subscribed_at: now, unsubscribed_at: nil, consented_at: now)
  end

  def unsubscribe!
    update!(status: :unsubscribed, unsubscribed_at: Time.current)
  end

  def anonymize!
    update!(email: "deleted-#{id}@invalid.local", source: nil, metadata: {}, status: :unsubscribed, unsubscribed_at: Time.current)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
