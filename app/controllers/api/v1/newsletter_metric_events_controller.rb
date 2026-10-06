module Api
  module V1
    class NewsletterMetricEventsController < ApplicationController
      EVENT_TYPES = %w[opened clicked].freeze

      def create
        edition = NewsletterEdition.published_for_public.find(event_params[:newsletter_edition_id])
        delivery = NewsletterDelivery.find_by(id: event_params[:newsletter_delivery_id]) if event_params[:newsletter_delivery_id].present?
        return render_error(code: "invalid_delivery", message: "A entrega informada não existe.", status: :unprocessable_content) if event_params[:newsletter_delivery_id].present? && delivery.nil?
        return render_error(code: "delivery_required", message: "A entrega é obrigatória para rastrear este evento.", status: :unprocessable_content) unless delivery
        return render_error(code: "invalid_delivery", message: "A entrega não pertence à edição informada.", status: :unprocessable_content) if delivery && delivery.newsletter_edition_id != edition.id

        event = NewsletterMetricEvent.new(event_params.merge(newsletter_edition: edition, occurred_at: Time.current))
        return render_error(code: "invalid_event", message: "Tipo de evento inválido.", status: :unprocessable_content) unless EVENT_TYPES.include?(event.event_type)
        event.save!
        render_success(data: { accepted: true }, status: :accepted)
      rescue ActiveRecord::RecordNotUnique
        render_success(data: { accepted: true, duplicate: true }, status: :accepted)
      end

      private

      def event_params
        params.require(:event).permit(:newsletter_edition_id, :newsletter_delivery_id, :event_type, :recipient_email, :link_url, :idempotency_key, metadata: {})
      end
    end
  end
end
