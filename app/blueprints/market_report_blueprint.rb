class MarketReportBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :slug, :period, :market_name, :region, :source_name, :source_url, :embed_url,
         :seo_title, :seo_description, :excerpt, :status, :visibility, :published_at,
         :metrics, :created_at, :updated_at

  field :documents_count do |report|
    report.documents.attachments.size
  end

  field :images_count do |report|
    report.images.attachments.size
  end

  field :seo_image_url do |report|
    next unless report.seo_image.attached?

    Rails.application.routes.url_helpers.rails_blob_url(report.seo_image, host: ENV.fetch("APP_PUBLIC_URL", "http://localhost:3000"))
  end

  view :detail do
    fields :body
    field :report_metrics do |report|
      MarketReportMetricBlueprint.render_as_hash(report.market_report_metrics)
    end
  end
end
