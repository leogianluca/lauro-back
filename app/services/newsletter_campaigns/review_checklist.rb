module NewsletterCampaigns
  class ReviewChecklist
    URL_PATTERN = %r{\A(?:https?://|#unsubscribe\z)}i

    def initialize(edition)
      @edition = edition
      @html = <<~HTML
        <meta name="viewport" content="width=device-width, initial-scale=1"><style>@media(max-width:680px){main{width:100%}}main{color:#182230}</style>#{HtmlRenderer.new(edition).call}<a href="#unsubscribe">Descadastrar-se</a>
      HTML
    end

    def call
      {
        subject: @edition.metadata["subject"].present?,
        preheader: @edition.metadata["preheader"].present?,
        content: @edition.body.present? || @edition.metadata["blocks"].present? || @edition.metadata["content_snapshots"].present?,
        images: image_sources_valid?,
        alt_text: image_alt_text_valid?,
        links: links_valid?,
        unsubscribe: @html.include?("#unsubscribe"),
        mobile: @html.include?("width=device-width") && @html.include?("@media"),
        contrast: @html.match?(%r{color:\s*#[0-9a-f]{6}}i),
        audience: audience_scope.exists?
      }
    end

    private

    def image_sources_valid?
      images = @html.scan(/<img\b[^>]*\bsrc="([^"]+)"/i).flatten
      return @edition.images.attached? if images.empty?

      images.all? { |source| source.match?(URL_PATTERN) }
    end

    def image_alt_text_valid?
      @html.scan(/<img\b[^>]*\balt="([^"]*)"/i).flatten.all?(&:present?)
    end

    def links_valid?
      @html.scan(/\b(?:href|src)="([^"]+)"/i).flatten.all? { |url| url.match?(URL_PATTERN) }
    end

    def audience_scope
      segment_id = @edition.metadata["segment_id"].presence
      segment_id ? NewsletterSegments::Matcher.new(NewsletterSegment.find(segment_id)).scope : NewsletterSubscriber.subscribed
    end
  end
end
