module Api
  module V1
    module Admin
      class SiteSettingsController < BaseController
        def index
          authorize SiteSetting
          settings = SiteSetting.order(:category, :key)
          pagination, settings = paginate_collection(settings)
          render_success(data: SiteSettingBlueprint.render_as_hash(settings), meta: pagination_meta(pagination))
        end

        def create
          setting = SiteSetting.new(setting_params)
          authorize setting
          setting.save!
          render_success(data: SiteSettingBlueprint.render_as_hash(setting), status: :created)
        end

        def update
          setting = SiteSetting.find(params[:id])
          authorize setting
          setting.update!(setting_params)
          render_success(data: SiteSettingBlueprint.render_as_hash(setting))
        end

        def destroy
          setting = SiteSetting.find(params[:id])
          authorize setting
          setting.destroy!
          render_success(data: nil)
        end

        private

        def setting_params
          params.require(:site_setting).permit(:key, :category, :public, :description, value: {})
        end
      end
    end
  end
end
