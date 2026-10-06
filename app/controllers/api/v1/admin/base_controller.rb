module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        before_action :authenticate_user!

        private

        def audit!(action, record)
          AuditLog.record!(user: current_user, action:, record:, request:)
        end
      end
    end
  end
end
