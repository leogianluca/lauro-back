class DealSubmission < ApplicationRecord
  include Discard::Model

  has_many_attached :images
  has_many_attached :documents
  belongs_to :converted_investment_card, class_name: "InvestmentCard", optional: true

  enum :status, {
    new_submission: "new",
    reviewing: "reviewing",
    accepted: "accepted",
    rejected: "rejected"
  }, default: :new_submission, validate: true

  validates :submitter_name, :submitter_email, presence: true
  validates :submitter_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :price_cents, :investment_min_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 2_147_483_647 },
            allow_nil: true
  validates :title, :city, :state, presence: true, if: :accepted?
  before_validation :normalize_email

  scope :recent, -> { order(created_at: :desc) }

  private

  def normalize_email
    self.submitter_email = submitter_email.to_s.strip.downcase
  end
end
