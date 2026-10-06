class MediaImportBatch < ApplicationRecord
  belongs_to :investment_card, optional: true
  belongs_to :newsletter_edition, optional: true
  has_many :items, class_name: "MediaImportItem", dependent: :destroy

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    completed_with_errors: "completed_with_errors",
    failed: "failed"
  }, default: :pending, validate: true

  validates :total_items, numericality: { greater_than_or_equal_to: 0 }
  validate :exactly_one_attachable

  def progress
    return 100 if total_items.zero?

    (((processed_items + failed_items).to_f / total_items) * 100).round
  end

  def refresh_progress!
    update!(
      processed_items: items.where(status: :processed).count,
      failed_items: items.where(status: :failed).count
    )
  end

  private

  def exactly_one_attachable
    return if investment_card.present? ^ newsletter_edition.present?

    errors.add(:base, "must belong to exactly one attachable resource")
  end
end
