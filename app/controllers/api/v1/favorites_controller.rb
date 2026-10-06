module Api
  module V1
    class FavoritesController < ApplicationController
      UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

      include PublicLocale
      before_action :authenticate_user!

      def index
        cards = current_user.favorite_investment_cards.published.kept.publicly_visible.order(created_at: :desc)
        pagination, cards = paginate_collection(cards)
        localized_cards = cards.map do |card|
          localize_public_record(card, InvestmentCardBlueprint.render_as_hash(card, view: :card))
        end
        render_success(
          data: localized_cards,
          meta: pagination_meta(pagination, public_locale_meta(localized_cards))
        )
      end

      def create
        card = public_card
        current_user.favorites.create_or_find_by!(investment_card: card)
        render_success(data: { favorited: true, investment_card_id: card.id }, status: :created)
      end

      def destroy
        card_id = params[:investment_card_id].to_s
        return render_not_found unless card_id.match?(UUID_PATTERN)

        current_user.favorites.where(investment_card_id: card_id).destroy_all
        render_success(data: { favorited: false, investment_card_id: card_id })
      end

      private

      def public_card
        InvestmentCard.published.kept.publicly_visible.find(params[:investment_card_id])
      end
    end
  end
end
