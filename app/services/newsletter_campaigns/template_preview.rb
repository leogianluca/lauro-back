module NewsletterCampaigns
  class TemplatePreview
    ALLOWED_TAGS = %w[p br strong em a h1 h2 h3 img].freeze
    ALLOWED_ATTRIBUTES = %w[href src alt].freeze

    def initialize(template)
      @template = template
    end

    def call(mobile: false)
      branding = @template.branding.to_h.stringify_keys
      primary_color = safe_color(branding["primary_color"])
      logo = safe_url(branding["logo_url"])
      footer = ERB::Util.html_escape(branding["footer_text"].to_s.presence || "Florida Investments")
      header = ERB::Util.html_escape(branding["header_text"].to_s.presence || "Novidades exclusivas")
      signature = ERB::Util.html_escape(branding["signature_text"].to_s)
      contacts = ERB::Util.html_escape(branding["contact_text"].to_s)
      socials = ERB::Util.html_escape(branding["social_links"].to_s)
      blocks = Array(@template.blocks).map { |block| render_block(block.to_h.stringify_keys, primary_color) }.join
      logo_html = logo ? %(<img src="#{ERB::Util.html_escape(logo)}" alt="Logo" style="max-width:160px;max-height:48px">) : ERB::Util.html_escape(@template.name)

      <<~HTML
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>body{margin:0;background:#f4f5f7;color:#182230;font-family:Arial,sans-serif}main{#{mobile ? "width:375px;max-width:100%;margin:0 auto" : "max-width:680px;margin:24px auto"};background:#fff}header{padding:#{mobile ? 20 : 24}px;border-bottom:4px solid #{primary_color};display:flex;justify-content:space-between;align-items:center;gap:16px;flex-wrap:wrap}section{padding:#{mobile ? 20 : 28}px;border-bottom:1px solid #e5e7eb}footer{padding:20px;background:#{primary_color};color:#fff;text-align:center;font-size:12px}img{display:block;width:100%;max-height:280px;object-fit:cover}a{color:#{primary_color};font-weight:700}</style></head><body><main><header>#{logo_html}<span>#{header}</span></header>#{blocks}<footer>#{footer}#{signature.present? ? "<br>#{signature}" : ""}#{contacts.present? ? "<br>#{contacts}" : ""}#{socials.present? ? "<br>#{socials}" : ""}</footer></main></body></html>
      HTML
    end

    private

    def render_block(block, primary_color)
      type = block["type"].to_s
      title = ERB::Util.html_escape(block["title"].to_s)
      content = block["content"].to_s
      image_url = safe_url(block["image_url"]) || (%w[hero banner].include?(type) ? safe_url(content) : nil)
      if image_url
        alt_text = ERB::Util.html_escape(block["alt_text"].to_s.presence || block["title"].to_s)
        return %(<section style="padding:0;background:#{primary_color}"><img src="#{ERB::Util.html_escape(image_url)}" alt="#{alt_text}"></section>)
      end

      body = ERB::Util.html_escape(content).gsub("\n", "<br>")
      if %w[cta property hero].include?(type)
        label = ERB::Util.html_escape(block["button_label"].to_s.presence || (type == "property" ? "Ver detalhes" : "Saiba mais"))
        url = safe_url(block["button_url"]) || "#preview"
        cta = %(<p><a href="#{ERB::Util.html_escape(url)}">#{label}</a></p>)
      else
        cta = ""
      end
      %(<section>#{title.present? ? "<h2>#{title}</h2>" : ""}<p>#{body}</p>#{cta}</section>)
    end

    def safe_url(value)
      value.to_s.match?(%r{\Ahttps?://}i) ? value.to_s : nil
    end

    def safe_color(value)
      value.to_s.match?(%r{\A\#[0-9a-fA-F]{6}\z}) ? value : "#0B1D3A"
    end
  end
end
