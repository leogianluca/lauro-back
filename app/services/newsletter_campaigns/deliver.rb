module NewsletterCampaigns
  class Deliver
    def initialize(edition, subscribers: nil)
      @edition = edition
      @subscribers = subscribers
    end

    def call
      counts = { sent: 0, failed: 0, skipped: 0 }
      (@subscribers || NewsletterSubscriber.subscribed).each do |subscriber|
        delivery = @edition.newsletter_deliveries.find_or_create_by!(newsletter_subscriber: subscriber)
        if delivery.sent?
          counts[:skipped] += 1
          next
        end

        counts[deliver_to(subscriber, delivery) ? :sent : :failed] += 1
      end
      counts
    end

    private

    def deliver_to(subscriber, delivery)
      return false if delivery.attempts >= NewsletterDelivery::MAX_ATTEMPTS

      while delivery.attempts < NewsletterDelivery::MAX_ATTEMPTS
        delivery.with_lock do
          delivery.update!(attempts: delivery.attempts + 1, last_attempt_at: Time.current)
        end
        begin
          NewsletterMailer.with(edition: @edition, subscriber: subscriber, delivery: delivery).edition.deliver_now
          delivery.update!(status: :sent, sent_at: Time.current, error_message: nil)
          record_delivery_event(subscriber, delivery)
          return true
        rescue StandardError => error
          delivery.update!(status: :failed, error_message: error.message)
        end
      end

      false
    end

    def record_delivery_event(subscriber, delivery)
      NewsletterMetricEvent.create!(
        newsletter_edition: @edition,
        newsletter_delivery: delivery,
        event_type: :delivered,
        recipient_email: subscriber.email,
        idempotency_key: "delivered:#{delivery.id}",
        occurred_at: Time.current
      )
    rescue ActiveRecord::RecordNotUnique
      nil
    end
  end
end
