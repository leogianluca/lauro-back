module Api
  module V1
    module Admin
      class LeadsController < BaseController
        def index
          leads = Lead.kept.recent
          leads = leads.where(status: params[:status]) if params[:status].present?
          pagination, leads = paginate_collection(leads)
          render_success(data: LeadBlueprint.render_as_hash(leads), meta: pagination_meta(pagination))
        end

        def show
          lead = Lead.kept.find(params[:id])
          authorize lead
          render_success(data: LeadBlueprint.render_as_hash(lead))
        end

        def update
          lead = Lead.kept.find(params[:id])
          authorize lead
          lead.update!(lead_params)
          audit!("lead.updated", lead)
          render_success(data: LeadBlueprint.render_as_hash(lead))
        end

        def destroy
          lead = Lead.kept.find(params[:id])
          authorize lead
          lead.discard!
          render_success(data: nil)
        end

        private

        def lead_params
          params.require(:lead).permit(:name, :email, :phone, :source, :status, :message, :consented_at, :assigned_to_id, :investment_card_id, :internal_notes, metadata: {})
        end
      end
    end
  end
end
