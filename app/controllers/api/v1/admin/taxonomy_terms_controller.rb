module Api
  module V1
    module Admin
      class TaxonomyTermsController < BaseController
        def index
          terms = policy_scope(TaxonomyTerm).kept
          terms = terms.where(kind: params[:kind]) if params[:kind].present?
          terms = terms.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params[:active].present?
          pagination, terms = paginate_collection(terms.ordered)
          render_success(data: TaxonomyTermBlueprint.render_as_hash(terms), meta: pagination_meta(pagination))
        end

        def show
          term = TaxonomyTerm.kept.find(params[:id])
          authorize term
          render_success(data: TaxonomyTermBlueprint.render_as_hash(term))
        end

        def create
          term = TaxonomyTerm.new(term_params)
          authorize term
          term.save!
          audit!("taxonomy_term.created", term)
          render_success(data: TaxonomyTermBlueprint.render_as_hash(term), status: :created)
        end

        def update
          term = TaxonomyTerm.kept.find(params[:id])
          authorize term
          term.update!(term_params)
          audit!("taxonomy_term.updated", term)
          render_success(data: TaxonomyTermBlueprint.render_as_hash(term))
        end

        def destroy
          term = TaxonomyTerm.kept.find(params[:id])
          authorize term
          term.discard!
          audit!("taxonomy_term.archived", term)
          render_success(data: nil)
        end

        private

        def term_params
          params.require(:taxonomy_term).permit(:kind, :name, :slug, :description, :active, :position, :parent_id, metadata: {})
        end
      end
    end
  end
end
