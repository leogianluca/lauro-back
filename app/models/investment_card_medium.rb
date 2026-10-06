class InvestmentCardMedium < ApplicationRecord
  belongs_to :investment_card
  has_one_attached :image

  acts_as_list scope: :investment_card

  validates :kind, inclusion: { in: %w[gallery floor_plan map] }
  validates :image, presence: true
  validate :image_has_supported_format

  private

  def image_has_supported_format
    return unless image.attached?

    errors.add(:image, "has an unsupported file type") unless InvestmentCards::MediaAttacher::IMAGE_TYPES.include?(image.blob.content_type)
    errors.add(:image, "is too large") if image.blob.byte_size > InvestmentCards::MediaAttacher::MAX_IMAGE_SIZE
  end
end
