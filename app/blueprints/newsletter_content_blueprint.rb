class NewsletterContentBlueprint < Blueprinter::Base
  identifier :id
  fields :title, :slug, :content_type, :category, :status, :favorite, :used_count, :last_used_at, :subtitle, :description, :cta_label, :cta_url, :cta_target, :tracking_key, :alt_text, :event_date, :event_time, :event_timezone, :event_location, :registration_url, :investment_card_id, :tags, :metadata, :published_at, :created_at, :updated_at
  field :images_count do |content|
    content.images.attachments.size
  end

  field :documents_count do |content|
    content.documents.attachments.size
  end

  field :image_urls do |content|
    content.images.attachments.map { |attachment| Rails.application.routes.url_helpers.rails_blob_url(attachment, host: ENV.fetch("APP_PUBLIC_URL", "http://localhost:3000")) }
  end
end
