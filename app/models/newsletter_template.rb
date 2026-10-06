class NewsletterTemplate < ApplicationRecord
  include Discard::Model
  has_many :newsletter_template_versions, dependent: :destroy
  enum :status, { draft: "draft", active: "active", archived: "archived" }, default: :draft, validate: true
  validates :name, presence: true
  validate :structured_content_has_expected_shape
  scope :available, -> { kept.order(updated_at: :desc) }
  before_save :clear_other_default, if: :default_template?

  def make_default!
    self.class.transaction do
      self.class.kept.where.not(id: id).update_all(default_template: false)
      update!(default_template: true)
    end
  end

  private

  def structured_content_has_expected_shape
    unless blocks.is_a?(Array) && blocks.all? { |block| block.is_a?(Hash) }
      errors.add(:blocks, "must be a list of objects")
    end
    errors.add(:branding, "must be an object") unless branding.is_a?(Hash)
  end

  def clear_other_default
    return unless default_template?

    self.class.kept.where.not(id: id).update_all(default_template: false)
  end
end
