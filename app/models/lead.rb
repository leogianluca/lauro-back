class Lead < ApplicationRecord
  include Discard::Model

  belongs_to :assigned_to, class_name: "User", optional: true
  belongs_to :investment_card, optional: true

  enum :status, {
    new_lead: "new",
    contacted: "contacted",
    qualified: "qualified",
    disqualified: "disqualified",
    converted: "converted"
  }, default: :new_lead, validate: true

  validates :name, :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :phone_has_valid_format

  scope :recent, -> { order(created_at: :desc) }

  private

  def phone_has_valid_format
    return if phone.blank?

    digits = phone.gsub(/\D/, "")
    return if phone.match?(/\A\+?[0-9][0-9\s().-]*\z/) && digits.length.between?(7, 15)

    errors.add(:phone, :invalid)
  end
end
