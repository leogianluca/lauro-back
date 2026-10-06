module Api
  module V1
    module Admin
      class AuditLogsController < BaseController
        def index
          authorize AuditLog
          logs = AuditLog.includes(:user).recent
          logs = logs.where(action: params[:action]) if params[:action].present?
          logs = logs.where(auditable_type: params[:auditable_type]) if params[:auditable_type].present?
          pagination, logs = paginate_collection(logs)
          render_success(data: logs.as_json(only: %i[id action auditable_type auditable_id changeset ip_address request_id created_at], include: { user: { only: %i[id email name role] } }), meta: pagination_meta(pagination))
        end
      end
    end
  end
end
