module NewsletterCampaigns
  class Compose
    def initialize(edition)
      @edition = edition
    end

    def call
      template_id = @edition.metadata["template_id"].presence
      content_ids = Array(@edition.metadata["content_ids"]).compact_blank
      template = template_id && NewsletterTemplate.kept.find_by(id: template_id)
      contents = NewsletterContent.kept.where(id: content_ids)
      previously_composed_ids = Array(@edition.metadata["content_snapshots"]).filter_map { |snapshot| snapshot.to_h["id"] }
      contents.where.not(id: previously_composed_ids).find_each do |content|
        content.update!(used_count: content.used_count + 1, last_used_at: Time.current)
      end
      campaign_blocks = if template && !@edition.metadata["blocks_customized"]
        template.blocks
      else
        Array(@edition.metadata["blocks"])
      end
      metadata = @edition.metadata.merge(
        "blocks" => campaign_blocks,
        "content_snapshots" => contents.map { |content| content_snapshot(content) }
      )
      @edition.update!(metadata:)
      @edition
    end

    private

    def content_snapshot(content)
      content.attributes.slice("id", "title", "content_type", "subtitle", "description", "cta_label", "cta_url", "registration_url", "alt_text").merge(
        "image_url" => content.images.attachments.first && Rails.application.routes.url_helpers.rails_blob_url(content.images.attachments.first, host: ENV.fetch("APP_PUBLIC_URL", "http://localhost:3000"))
      )
    end
  end
end
