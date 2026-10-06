require "openssl"

module Api
  module V1
    class NewsletterWebhooksController < ApplicationController
      PROVIDER_EVENTS = {
        "delivered" => "delivered",
        "delivery" => "delivered",
        "bounce" => "bounced",
        "bounced" => "bounced",
        "complaint" => "spam_complaint",
        "spam_complaint" => "spam_complaint",
        "unsubscribe" => "unsubscribed",
        "unsubscribed" => "unsubscribed"
      }.freeze

      def create
        return render_error(code: "webhook_not_configured", message: "Webhook secret is not configured.", status: :service_unavailable) unless webhook_secret.present?
        return render_error(code: "invalid_signature", message: "Invalid webhook signature.", status: :unauthorized) unless valid_signature?

        payload = JSON.parse(request.raw_post).deep_stringify_keys
        event_type = PROVIDER_EVENTS[payload["event"].to_s.downcase] || PROVIDER_EVENTS[payload["type"].to_s.downcase]
        return render_error(code: "invalid_event", message: "Unsupported provider event.", status: :unprocessable_content) unless event_type

        delivery = find_delivery(payload)
        return render_error(code: "delivery_not_found", message: "The delivery could not be identified.", status: :unprocessable_content) unless delivery

        event = NewsletterMetricEvent.create!(
          newsletter_edition: delivery.newsletter_edition,
          newsletter_delivery: delivery,
          event_type:,
          recipient_email: delivery.newsletter_subscriber.email,
          idempotency_key: payload["idempotency_key"].presence || payload["event_id"].presence || "webhook:#{event_type}:#{delivery.id}:#{payload["occurred_at"]}",
          metadata: payload.slice("provider", "reason", "code", "raw_event"),
          occurred_at: parse_time(payload["occurred_at"])
        )
        delivery.newsletter_subscriber.unsubscribe! if event_type == "unsubscribed"
        render_success(data: { accepted: true, event_id: event.id }, status: :accepted)
      rescue JSON::ParserError
        render_error(code: "invalid_payload", message: "Webhook payload must be valid JSON.", status: :bad_request)
      rescue ActiveRecord::RecordNotUnique
        render_success(data: { accepted: true, duplicate: true }, status: :accepted)
      end

      private

      def webhook_secret
        ENV["NEWSLETTER_WEBHOOK_SECRET"].to_s
      end

      def valid_signature?
        supplied = request.headers["X-Newsletter-Signature"].to_s.sub(/^sha256=/, "")
        expected = OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, request.raw_post)
        supplied.present? && supplied.bytesize == expected.bytesize && ActiveSupport::SecurityUtils.secure_compare(supplied, expected)
      end

      def find_delivery(payload)
        return NewsletterDelivery.find_by(id: payload["newsletter_delivery_id"]) if payload["newsletter_delivery_id"].present?

        edition = NewsletterEdition.find_by(id: payload["newsletter_edition_id"])
        recipient = payload["recipient_email"].to_s.strip.downcase
        return unless edition && recipient.present?

        edition.newsletter_deliveries.joins(:newsletter_subscriber).find_by(newsletter_subscribers: { email: recipient })
      end

      def parse_time(value)
        value.present? ? (Time.zone.parse(value.to_s) || Time.current) : Time.current
      rescue ArgumentError
        Time.current
      end
    end
  end
end
