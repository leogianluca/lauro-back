class ContentPage < ApplicationRecord
  include Discard::Model
  extend FriendlyId

  friendly_id :title, use: :slugged

  has_many_attached :images
  has_many_attached :documents
  has_one_attached :seo_image

  enum :status, {
    draft: "draft",
    published: "published",
    archived: "archived"
  }, default: :draft, validate: true

  enum :visibility, {
    public: "public",
    private: "private"
  }, prefix: true, default: :public, validate: true

  validates :title, :slug, :page_type, :status, :visibility, presence: true
  validates :slug, uniqueness: true
  validate :content_blocks_are_a_list

  scope :published_for_public, -> { published.kept.where(visibility: :public).order(:title) }

  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def archive!
    update!(status: :archived)
  end

  def hide!
    update!(visibility: :private)
  end

  def show!
    update!(visibility: :public)
  end

  def documents_count
    documents.attachments.size
  end

  def should_generate_new_friendly_id?
    slug.blank?
  end

  private

  def content_blocks_are_a_list
    errors.add(:content_blocks, "must be a list") unless content_blocks.is_a?(Array)
  end
end
