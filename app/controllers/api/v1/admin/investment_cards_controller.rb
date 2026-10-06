module Api
  module V1
    module Admin
      class InvestmentCardsController < BaseController
        def index
          cards = InvestmentCards::FilterQuery.new(InvestmentCard.kept, params).call
          pagination, cards = paginate_collection(cards)
          render_success(data: InvestmentCardBlueprint.render_as_hash(cards, view: :detail), meta: pagination_meta(pagination))
        end

        def show
          card = InvestmentCard.kept.find(params[:id])
          authorize card
          render_success(data: InvestmentCardBlueprint.render_as_hash(card, view: :detail))
        end

        def create
          card = InvestmentCard.new(card_params)
          authorize card
          card.save!
          audit!("investment_card.created", card)
          render_success(data: InvestmentCardBlueprint.render_as_hash(card, view: :detail), status: :created)
        end

        def update
          card = InvestmentCard.kept.find(params[:id])
          authorize card
          card.update!(card_params)
          audit!("investment_card.updated", card)
          render_success(data: InvestmentCardBlueprint.render_as_hash(card, view: :detail))
        end

        def destroy
          card = InvestmentCard.kept.find(params[:id])
          authorize card
          card.discard!
          audit!("investment_card.archived", card)
          render_success(data: nil)
        end

        def media
          card = InvestmentCard.kept.find(params[:id])
          authorize card, :update?
          InvestmentCards::MediaAttacher.new(card, media_params).call
          render_success(data: InvestmentCardBlueprint.render_as_hash(card, view: :detail))
        end

        def remove_media
          card = InvestmentCard.kept.find(params[:id])
          authorize card, :update?
          attachment = Attachments::Purge.new(card, name: params[:name], attachment_id: params[:attachment_id], user: current_user).call
          render_success(data: { attachment_id: attachment.id, status: "queued" }, status: :accepted)
        end

        def document
          card = InvestmentCard.kept.find(params[:id])
          authorize card, :show?
          attachment = card.documents.attachments.find(params[:attachment_id])
          redirect_to rails_blob_path(attachment, disposition: "attachment")
        end

        def make_public
          card = InvestmentCard.kept.find(params[:id])
          authorize card, :make_public?
          card.show!
          audit!("investment_card.make_public", card)
          render_success(data: InvestmentCardBlueprint.render_as_hash(card, view: :detail))
        end

        %w[publish archive hide feature unfeature mark_expert_curated unmark_expert_curated].each do |action|
          define_method(action) do
            card = InvestmentCard.kept.find(params[:id])
            authorize card, "#{action}?"
            card.public_send("#{action}!")
            audit!("investment_card.#{action}", card)
            render_success(data: InvestmentCardBlueprint.render_as_hash(card, view: :detail))
          end
        end

        private

        def card_params
          permitted = params.require(:investment_card).permit(
            :title, :slug, :summary, :description, :category, :asset_type, :strategy,
            :city, :state, :region, :country, :address_line1, :address_line2, :zip_code, :latitude, :longitude,
            :investment_broker_id, :investment_company_id, :investment_location_id,
            :status, :visibility, :card_level, :featured,
            :expert_curated, :featured_position, :price_cents, :price_currency,
            :investment_min_cents, :investment_max_cents, :source_url,
            :external_reference, :published_at, :current_income_cents, :projected_income_cents,
            :noi_current_cents, :noi_projected_cents, :cap_rate_current, :cap_rate_projected,
            :cash_on_cash, :occupancy_rate, :gross_yield_percent, :hpi_10_year_percent,
            :estimated_months, :sector, :ebitda_annual_cents,
            :ebitda_margin, :operating_model, :investor_participation, :investment_thesis,
            :annual_profit_cents, :owner_salary_annual_cents, :owner_time_in_business_years,
            :owner_involvement, :franchise, :sale_reason, :visa_eligibility,
            :alt_text, :disclaimer, :source_name, :verified_at, :curated_by_id,
            :market_status, :down_payment_percent, :down_payment_cents, :living_area_sqft,
            :bedrooms, :bathrooms, :year_built, :estimated_roi_min, :estimated_roi_max,
            :equity_generated_min_cents, :equity_generated_max_cents, :financing_available,
            :quota_available, :category_taxonomy_id, :asset_type_taxonomy_id,
            :strategy_taxonomy_id, :market_taxonomy_id, :assumptions, :market_context,
            :investment_profile, :return_strategy, :expert_curated_reason,
            :expert_curated_analysis, :seo_title, :seo_description,
            investment_broker_attributes: %i[id name email phone company_name _destroy],
            investment_company_attributes: %i[id name sector website _destroy],
            investment_location_attributes: %i[id name address_line1 address_line2 city state zip_code country latitude longitude _destroy],
            investment_card_metrics_attributes: %i[id taxonomy_term_id label value unit position featured description _destroy],
            highlights: [], risks: [], tags: [], due_diligence: {}, financing: {}, metadata: {}, property_details: {}, business_details: {}
          )

          normalize_taxonomy_values!(permitted)
          permitted
        end

        # The taxonomy is the source of truth. Keeping the legacy text fields in
        # sync preserves public filtering while preventing spelling variants.
        def normalize_taxonomy_values!(permitted)
          {
            category_taxonomy_id: [ :category, "category" ],
            asset_type_taxonomy_id: [ :asset_type, "asset_type" ],
            strategy_taxonomy_id: [ :strategy, "strategy" ],
            market_taxonomy_id: [ nil, "market" ]
          }.each do |taxonomy_key, (legacy_key, expected_kind)|
            next if permitted[taxonomy_key].blank?

            term = TaxonomyTerm.find_by(id: permitted[taxonomy_key])
            next unless term&.kind == expected_kind

            permitted[legacy_key] = term.slug if legacy_key
          end
        end

        def media_params
          params.permit(:cover_image, :seo_image, gallery_images: [], documents: [])
        end
      end
    end
  end
end
