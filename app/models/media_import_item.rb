class MediaImportItem < ApplicationRecord
  MAX_ATTEMPTS = 3

  belongs_to :media_import_batch
  has_one_attached :file

  enum :kind, {
    gallery_image: "gallery_image",
    document: "document"
  }, validate: true

  enum :status, {
    pending: "pending",
    processed: "processed",
    failed: "failed"
  }, default: :pending, validate: true

  validates :kind, :status, presence: true
  validates :attempts, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_ATTEMPTS }

  scope :retryable, -> { failed.where("attempts < ?", MAX_ATTEMPTS) }
end
