class InvestmentCardMediumBlueprint < Blueprinter::Base
  identifier :id

  fields :kind, :alt_text, :caption, :position, :metadata

  field :image_url do |medium|
    next unless medium.image.attached?

    Rails.application.routes.url_helpers.rails_blob_url(
      medium.image,
      host: ENV.fetch("APP_PUBLIC_URL", "http://localhost:3000")
    )
  end
end
