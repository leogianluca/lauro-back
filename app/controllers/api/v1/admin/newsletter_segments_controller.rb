module Api
  module V1
    module Admin
      class NewsletterSegmentsController < BaseController
        before_action :set_segment, only: %i[show update destroy preview duplicate]

        def index
          authorize NewsletterSegment
          segments = NewsletterSegment.where.not(status: :archived)
          segments = segments.where(status: params[:status]) if params[:status].present?
          if params[:q].present?
            query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s)}%"
            segments = segments.where("name ILIKE :query OR description ILIKE :query", query:)
          end
          pagination, segments = paginate_collection(segments.order(updated_at: :desc))
          render_success(data: segments, meta: pagination_meta(pagination))
        end

        def show
          authorize @segment
          render_success(data: @segment)
        end

        def create
          segment = NewsletterSegment.new(segment_params)
          authorize segment
          segment.save!
          audit!("newsletter_segment.created", segment)
          render_success(data: segment, status: :created)
        end

        def update
          authorize @segment
          @segment.update!(segment_params)
          audit!("newsletter_segment.updated", @segment)
          render_success(data: @segment)
        end

        def destroy
          authorize @segment
          @segment.update!(status: :archived)
          audit!("newsletter_segment.archived", @segment)
          render_success(data: nil)
        end

        def duplicate
          authorize @segment, :create?
          copy = @segment.dup
          copy.name = "#{@segment.name} (cópia)"
          copy.contacts_count = 0
          copy.status = :active
          copy.save!
          audit!("newsletter_segment.duplicated", copy)
          render_success(data: copy, status: :created)
        end

        def preview
          authorize @segment, :show?
          matcher = NewsletterSegments::Matcher.new(@segment)
          count = matcher.count
          @segment.update!(contacts_count: count)
          sample = matcher.scope.first(10).map { |subscriber| { id: subscriber.id, email: subscriber.email } }
          render_success(data: { segment: @segment, count:, sample: })
        end

        private

        def set_segment
          @segment = NewsletterSegment.find(params[:id])
        end

        def segment_params
          params.require(:newsletter_segment).permit(:name, :description, :status, :logic, :contacts_count, conditions: [ :field, :operator, :value, { value: [] } ])
        end
      end
    end
  end
end
