module Api
  module V1
    module Admin
      class InvestmentCardMediaController < BaseController
        def create
          card = InvestmentCard.kept.find(params[:investment_card_id])
          authorize card, :update?
          medium = card.investment_card_media.build(media_params.except(:image))
          medium.image.attach(media_params[:image])
          medium.save!
          audit!("investment_card_media.created", medium)
          render_success(data: InvestmentCardMediumBlueprint.render_as_hash(medium), status: :created)
        end

        def update
          card = InvestmentCard.kept.find(params[:investment_card_id])
          authorize card, :update?
          medium = card.investment_card_media.find(params[:id])
          medium.update!(media_params.except(:image))
          medium.image.attach(media_params[:image]) if media_params[:image].present?
          audit!("investment_card_media.updated", medium)
          render_success(data: InvestmentCardMediumBlueprint.render_as_hash(medium))
        end

        def destroy
          card = InvestmentCard.kept.find(params[:investment_card_id])
          authorize card, :update?
          medium = card.investment_card_media.find(params[:id])
          medium.destroy!
          audit!("investment_card_media.deleted", medium)
          render_success(data: nil)
        end

        private

        def media_params
          params.permit(:image, :kind, :alt_text, :caption, :position, metadata: {})
        end
      end
    end
  end
end
