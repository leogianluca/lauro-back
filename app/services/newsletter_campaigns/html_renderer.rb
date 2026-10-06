module NewsletterCampaigns
  class HtmlRenderer
    ALLOWED_TAGS = %w[p br strong em a ul ol li h1 h2 h3 img].freeze
    ALLOWED_ATTRIBUTES = %w[href src alt].freeze

    def initialize(edition)
      @edition = edition
    end

    def call
      sections = []
      sections << render_body(@edition.body) if @edition.body.present?
      Array(@edition.metadata["blocks"]).each { |block| sections << render_block(block) }
      Array(@edition.metadata["content_snapshots"]).each { |content| sections << render_content(content) }
      sanitize(sections.compact.join)
    end

    private

    def render_body(body)
      "<section>#{body}</section>"
    end

    def render_block(block)
      block = block.to_h.stringify_keys
      title = ERB::Util.html_escape(block["title"].to_s)
      content = block["content"].to_s
      image = safe_url(block["image_url"])
      image_html = image ? %(<img src="#{ERB::Util.html_escape(image)}" alt="#{ERB::Util.html_escape(block["alt_text"].to_s)}">) : ""
      body = ERB::Util.html_escape(content).gsub("\n", "<br>")
      link = safe_url(block["button_url"])
      cta = link ? %(<p><a href="#{ERB::Util.html_escape(link)}">#{ERB::Util.html_escape(block["button_label"].to_s.presence || "Saiba mais")}</a></p>) : ""
      "<section>#{image_html}#{title.present? ? "<h2>#{title}</h2>" : ""}<p>#{body}</p>#{cta}</section>"
    end

    def render_content(content)
      content = content.to_h.stringify_keys
      title = ERB::Util.html_escape(content["title"].to_s)
      description = content["description"].to_s.presence || content["subtitle"].to_s
      image = safe_url(content["image_url"])
      image_html = image ? %(<img src="#{ERB::Util.html_escape(image)}" alt="#{ERB::Util.html_escape(content["alt_text"].to_s)}">) : ""
      body = ERB::Util.html_escape(description).gsub("\n", "<br>")
      link_url = safe_url(content["cta_url"]) || safe_url(content["registration_url"])
      link = link_url ? %(<p><a href="#{ERB::Util.html_escape(link_url)}">#{ERB::Util.html_escape(content["cta_label"].to_s.presence || "Saiba mais")}</a></p>) : ""
      "<section>#{image_html}<h2>#{title}</h2><p>#{body}</p>#{link}</section>"
    end

    def sanitize(html)
      clean_html = html.to_s.gsub(%r{<script\b[^>]*>.*?</script>}mi, "")
      ActionController::Base.helpers.sanitize(clean_html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
    end

    def safe_url(value)
      value.to_s.match?(%r{\Ahttps?://}i) ? value.to_s : nil
    end
  end
end
