module NewsletterCampaigns
  class ContentPreview
    def initialize(content)
      @content = content
    end

    def call(mobile: false)
      title = ERB::Util.html_escape(@content.title)
      subtitle = ERB::Util.html_escape(@content.subtitle.to_s)
      description = ERB::Util.html_escape(@content.description.to_s)
      image = image_html
      link = link_html

      width = mobile ? "width:375px;max-width:100%;margin:0 auto" : "max-width:680px;margin:24px auto"
      <<~HTML
        <!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1"><style>body{margin:0;background:#f4f5f7;color:#182230;font-family:Arial,sans-serif}main{#{width};background:#fff;border:1px solid #e5e7eb}section{padding:#{mobile ? 20 : 28}px}img{display:block;width:100%;max-height:320px;object-fit:cover}h1{margin:0 0 8px;font-size:#{mobile ? 24 : 28}px}p{line-height:1.6;color:#475467}a{color:#0b57d0;font-weight:700}</style></head><body><main>#{image}<section><p>#{ERB::Util.html_escape(@content.content_type.to_s)}</p><h1>#{title}</h1>#{subtitle.present? ? "<h2>#{subtitle}</h2>" : ""}#{description.present? ? "<p>#{description}</p>" : ""}#{link}</section></main></body></html>
      HTML
    end

    private

    def image_html
      attachment = @content.images.attachments.first
      return "" unless attachment

      url = Rails.application.routes.url_helpers.rails_blob_url(attachment, host: ENV.fetch("APP_PUBLIC_URL", "http://localhost:3000"))
      "<img src=\"#{ERB::Util.html_escape(url)}\" alt=\"#{ERB::Util.html_escape(@content.alt_text.to_s)}\">"
    end

    def link_html
      url = @content.cta_url.presence || @content.registration_url.presence
      return "" unless url

      label = @content.cta_label.presence || "Saiba mais"
      "<p><a href=\"#{ERB::Util.html_escape(url)}\">#{ERB::Util.html_escape(label)}</a></p>"
    end
  end
end
