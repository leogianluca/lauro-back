module Api
  module V1
    class SiteSettingsController < ApplicationController
      def index
        settings = SiteSetting.publicly_visible.order(:category, :key)
        render_success(data: settings.each_with_object({}) { |setting, result| result[setting.key] = setting.value })
      end
    end
  end
end
