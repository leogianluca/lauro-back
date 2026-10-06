module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        respond_to :json

        private

        def respond_with(resource, _opts = {})
          AuditLog.record!(user: resource, action: "auth.login", record: resource, request:)
          render json: {
            data: UserBlueprint.render_as_hash(resource).merge(token: request.env["warden-jwt_auth.token"]),
            meta: {},
            errors: []
          }, status: :ok
        end

        def respond_to_on_destroy
          AuditLog.record!(user: current_user, action: "auth.logout", record: current_user, request:) if current_user
          render json: {
            data: nil,
            meta: {},
            errors: []
          }, status: :ok
        end
      end
    end
  end
end
