class ContentPageBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :slug, :page_type, :template_key, :eyebrow, :excerpt, :content_blocks,
         :seo_title, :seo_description, :status, :visibility,
         :published_at, :metadata, :created_at, :updated_at

  field :images_count do |page|
    page.images.attachments.size
  end

  field :seo_image_url do |page|
    next unless page.seo_image.attached?

    Rails.application.routes.url_helpers.rails_blob_url(page.seo_image, host: ENV.fetch("APP_PUBLIC_URL", "http://localhost:3000"))
  end

  view :detail do
    fields :body, :documents_count
  end

  field :documents_count do |page|
    page.documents.attachments.size
  end
end
