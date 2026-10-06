module NewsletterCampaigns
  class LinkTracker
    def initialize(html, delivery)
      @html = html.to_s
      @delivery = delivery
    end

    def call
      return @html unless @delivery

      @html.gsub(/href=(['"])(https?:\/\/[^'"]+)\1/i) do
        quote = Regexp.last_match(1)
        destination = Regexp.last_match(2)
        token = Rails.application.message_verifier("newsletter-link").generate(
          { "delivery_id" => @delivery.id, "url" => destination },
          purpose: "newsletter_click"
        )
        "href=#{quote}#{tracking_url(token)}#{quote}"
      end
    end

    private

    def tracking_url(token)
      host = ENV.fetch("APP_HOST", "localhost")
      port = ENV["APP_PORT"].presence
      "#{ENV.fetch("APP_PROTOCOL", "http")}://#{host}#{port ? ":#{port}" : ""}/api/v1/newsletter_tracking/#{token}/click"
    end
  end
end
