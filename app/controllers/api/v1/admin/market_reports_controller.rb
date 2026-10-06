module Api
  module V1
    module Admin
      class MarketReportsController < BaseController
        def index
          reports = MarketReport.kept.order(period: :desc, updated_at: :desc)
          pagination, reports = paginate_collection(reports)
          render_success(data: MarketReportBlueprint.render_as_hash(reports, view: :detail), meta: pagination_meta(pagination))
        end

        def show
          report = MarketReport.kept.find(params[:id])
          authorize report
          render_success(data: MarketReportBlueprint.render_as_hash(report, view: :detail))
        end

        def create
          report = MarketReport.new(report_params)
          authorize report
          report.save!
          render_success(data: MarketReportBlueprint.render_as_hash(report, view: :detail), status: :created)
        end

        def update
          report = MarketReport.kept.find(params[:id])
          authorize report
          report.update!(report_params)
          render_success(data: MarketReportBlueprint.render_as_hash(report, view: :detail))
        end

        def destroy
          report = MarketReport.kept.find(params[:id])
          authorize report
          report.discard!
          render_success(data: nil)
        end

        def media
          report = MarketReport.kept.find(params[:id])
          authorize report, :update?
          NewsletterContents::MediaAttacher.new(report, images: params[:images], documents: params[:documents]).call
          report.seo_image.attach(params[:seo_image]) if params[:seo_image].present?
          render_success(data: MarketReportBlueprint.render_as_hash(report, view: :detail))
        end

        def remove_media
          report = MarketReport.kept.find(params[:id])
          authorize report, :update?
          attachment = Attachments::Purge.new(report, name: params[:name], attachment_id: params[:attachment_id], user: current_user).call
          render_success(data: { attachment_id: attachment.id, status: "queued" }, status: :accepted)
        end

        def make_public
          report = MarketReport.kept.find(params[:id])
          authorize report, :make_public?
          report.show!
          render_success(data: MarketReportBlueprint.render_as_hash(report, view: :detail))
        end

        %w[publish archive hide].each do |action|
          define_method(action) do
            report = MarketReport.kept.find(params[:id])
            authorize report, "#{action}?"
            report.public_send("#{action}!")
            render_success(data: MarketReportBlueprint.render_as_hash(report, view: :detail))
          end
        end

        private

        def report_params
          params.require(:market_report).permit(
            :title, :slug, :period, :excerpt, :body, :status, :visibility,
            :published_at, :market_name, :region, :source_name, :source_url,
            :embed_url, :seo_title, :seo_description, metrics: {},
            market_report_metrics_attributes: %i[id taxonomy_term_id label value unit variation position featured description _destroy],
            metadata: {}
          )
        end
      end
    end
  end
end
