module Api
  module V1
    class InvestmentCardsController < ApplicationController
      include PublicLocale
      MAX_FAVORITE_QUERY_IDS = 10_000

      def index
        return invalid_price_filter_response if invalid_price_filter?

        cards = InvestmentCards::FilterQuery.new(public_cards, params).call
        render_cards(cards, extra_meta: unavailable_favorite_ids_meta)
      end

      def favorites
        ids = Array(params[:ids]).map { |id| id.to_s.strip }.reject(&:blank?).uniq
        if ids.empty? || ids.size > MAX_FAVORITE_QUERY_IDS
          return render_error(
            code: "invalid_favorite_ids",
            field: "ids",
            message: "Provide between 1 and #{MAX_FAVORITE_QUERY_IDS} public card IDs.",
            status: :unprocessable_content
          )
        end

        return invalid_price_filter_response if invalid_price_filter?

        cards = InvestmentCards::FilterQuery.new(public_cards, params.merge(ids: ids)).call
        cards = cards.reorder(nil).in_order_of(:id, ids) if params[:sort].blank?
        render_cards(cards, extra_meta: unavailable_favorite_ids_meta(ids))
      end

      def show
        card = public_cards.find_by!(slug: params[:slug])

        payload = localize_public_record(card, InvestmentCardBlueprint.render_as_hash(card, view: :detail))
        render_success(data: payload)
      end

      def document
        card = public_cards.find_by!(slug: params[:slug])
        attachment = card.documents.attachments.find(params[:attachment_id])
        redirect_to rails_blob_path(attachment, disposition: "attachment"), allow_other_host: false
      end

      private

      def invalid_price_filter?
        @invalid_price_filter_field = %i[min_price_cents max_price_cents].find do |field|
          value = params[field]
          next false if value.blank?

          raw_value = value.to_s
          !raw_value.match?(/\A\d+\z/) || raw_value.length > 19 || Integer(raw_value, 10) > 9_223_372_036_854_775_807
        end
        return true if @invalid_price_filter_field

        minimum = integer_price_filter(:min_price_cents)
        maximum = integer_price_filter(:max_price_cents)
        minimum && maximum && minimum > maximum
      end

      def integer_price_filter(field)
        value = params[field]
        Integer(value.to_s, 10) if value.present?
      end

      def invalid_price_filter_response
        render_error(
          code: "invalid_price_filter",
          field: @invalid_price_filter_field || "min_price_cents",
          message: "Price filters must be non-negative integer cents and the minimum cannot exceed the maximum.",
          status: :unprocessable_content
        )
      end

      def render_cards(cards, extra_meta: {})
        pagination, cards = paginate_collection(cards)

        localized_cards = cards.map do |card|
          localize_public_record(card, InvestmentCardBlueprint.render_as_hash(card, view: :card))
        end
        render_success(
          data: localized_cards,
          meta: pagination_meta(pagination, public_locale_meta(localized_cards).merge(extra_meta))
        )
      end

      def unavailable_favorite_ids_meta(ids = requested_favorite_ids)
        return {} if ids.empty?

        valid_ids = ids.select { |id| id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i) }
        visible_ids = public_cards.where(id: valid_ids).pluck(:id).map(&:to_s)
        { unavailable_ids: ids - visible_ids }
      end

      def requested_favorite_ids
        raw_ids = params[:ids]
        values = raw_ids.is_a?(Array) ? raw_ids : raw_ids.to_s.split(",")
        values.map { |id| id.to_s.strip }.reject(&:blank?).uniq.first(MAX_FAVORITE_QUERY_IDS)
      end

      def public_cards
        InvestmentCard.published.kept.publicly_visible
          .with_attached_cover_image
          .with_attached_seo_image
          .with_attached_gallery_images
          .with_attached_documents
          .includes(
            :investment_broker, :investment_company, :investment_location,
            :category_taxonomy, :asset_type_taxonomy, :strategy_taxonomy, :market_taxonomy,
            investment_card_metrics: :taxonomy_term,
            investment_card_media: { image_attachment: :blob }
          )
      end
    end
  end
end
