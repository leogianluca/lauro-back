module Api
  module V1
    class SiteAnalyticsEventsController < ApplicationController
      PUBLIC_PATH = %r{\A/(?:\z|(?:opportunities|favorites|intelligence|market-reports|newsletter|strategy|about|selection-process|pages|contact|submit-deal)(?:/|\z))}

      def create
        event = SiteAnalyticsEvent.new(event_params)
        event.occurred_at = Time.current
        event.save!
        head :no_content
      end

      private

      def event_params
        permitted = params.require(:event).permit(
          :event_type, :path, :target_path, :session_id, :referrer_host,
          :utm_source, :utm_medium, :utm_campaign, :device_type
        )
        permitted[:path] = clean_path(permitted[:path])
        permitted[:target_path] = clean_path(permitted[:target_path]) if permitted[:target_path].present?
        %i[referrer_host utm_source utm_medium utm_campaign].each do |key|
          permitted[key] = permitted[key].to_s.strip.first(120) if permitted[key].present?
        end
        permitted
      end

      def clean_path(value)
        path = value.to_s
        raise ActionController::BadRequest unless path.match?(PUBLIC_PATH) && !path.start_with?("//")
        raise ActionController::BadRequest if path.include?("?") || path.include?("#") || path.length > 255

        path
      end
    end
  end
end
