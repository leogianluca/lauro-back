class NewsletterEditionBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :slug, :edition_date, :cta_label, :cta_url, :seo_title, :seo_description,
         :excerpt, :status, :visibility, :published_at,
         :created_at, :updated_at

  field :images_count do |edition|
    edition.images.attachments.size
  end

  field :documents_count do |edition|
    edition.documents.attachments.size
  end

  field :seo_image_url do |edition|
    next unless edition.seo_image.attached?

    Rails.application.routes.url_helpers.rails_blob_url(edition.seo_image, host: ENV.fetch("APP_PUBLIC_URL", "http://localhost:3000"))
  end

  field :cover_image_url do |edition|
    next unless edition.cover_image.attached?

    Rails.application.routes.url_helpers.rails_blob_url(edition.cover_image, host: ENV.fetch("APP_PUBLIC_URL", "http://localhost:3000"))
  end

  view :detail do
    fields :body, :metadata
  end
end
