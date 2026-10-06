module Api
  module V1
    class MarketReportsController < ApplicationController
      include PublicLocale

      def index
        reports = public_reports
        pagination, reports = paginate_collection(reports)
        localized_reports = reports.map { |report| localize_public_record(report, MarketReportBlueprint.render_as_hash(report)) }
        render_success(data: localized_reports, meta: pagination_meta(pagination, public_locale_meta(localized_reports)))
      end

      def show
        report = public_reports.find_by!(slug: params[:slug])
        render_success(data: localize_public_record(report, MarketReportBlueprint.render_as_hash(report, view: :detail)))
      end

      private

      def public_reports
        MarketReport.published_for_public
          .with_attached_documents
          .with_attached_images
          .with_attached_seo_image
          .includes(market_report_metrics: :taxonomy_term)
      end
    end
  end
end
