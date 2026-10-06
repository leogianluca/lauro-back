module Api
  module V1
    class LeadsController < ApplicationController
      def create
        return render_error(code: "consent_required", message: "Consent is required to submit a contact request.", status: :unprocessable_content) unless ActiveModel::Type::Boolean.new.cast(params[:consent])

        attributes = lead_params.to_h
        if attributes["investment_card_id"].present?
          card = InvestmentCard.published.kept.publicly_visible.find_by(id: attributes["investment_card_id"])
          return render_not_found unless card

          attributes["investment_card_id"] = card.id
        end

        lead = Lead.new(attributes)
        lead.consented_at = Time.current
        lead.save!
        render_success(data: PublicLeadBlueprint.render_as_hash(lead), status: :created)
      end

      private

      def lead_params
        params.require(:lead).permit(:name, :email, :phone, :source, :message, :investment_card_id, metadata: {})
      end
    end
  end
end
