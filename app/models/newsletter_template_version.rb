class NewsletterTemplateVersion < ApplicationRecord
  belongs_to :newsletter_template
  belongs_to :created_by, class_name: "User", optional: true

  validates :version_number, presence: true
end
