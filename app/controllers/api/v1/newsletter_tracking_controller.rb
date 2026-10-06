module Api
  module V1
    class NewsletterTrackingController < ApplicationController
      TRANSPARENT_GIF = [
        "R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=="
      ].pack("m0")

      def open
        delivery = NewsletterDelivery.find_signed!(params[:token], purpose: "newsletter_open")
        NewsletterMetricEvent.create!(
          newsletter_edition: delivery.newsletter_edition,
          newsletter_delivery: delivery,
          event_type: :opened,
          idempotency_key: "open:#{delivery.id}",
          occurred_at: Time.current
        )
      rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        # Tracking must never expose delivery state or break the recipient's email client.
      ensure
        send_data TRANSPARENT_GIF, type: "image/gif", disposition: "inline"
      end

      def click
        payload = Rails.application.message_verifier("newsletter-link").verify(params[:token], purpose: "newsletter_click")
        delivery = NewsletterDelivery.find(payload.fetch("delivery_id"))
        url = payload.fetch("url")
        raise ActionController::BadRequest unless url.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))

        NewsletterMetricEvent.create!(newsletter_edition: delivery.newsletter_edition, newsletter_delivery: delivery, event_type: :clicked, link_url: url, idempotency_key: "click:#{delivery.id}:#{Digest::SHA256.hexdigest(url)}", occurred_at: Time.current)
        redirect_to url, allow_other_host: true
      rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordNotUnique, ActiveSupport::MessageVerifier::InvalidSignature, KeyError, ActionController::BadRequest
        render_error(code: "invalid_tracking_link", message: "The tracking link is invalid.", status: :bad_request)
      end
    end
  end
end
