class NewsletterApprovalComment < ApplicationRecord
  belongs_to :newsletter_edition
  belongs_to :user
  enum :status, { open: "open", resolved: "resolved" }, default: :open, validate: true
  validates :body, presence: true
end
