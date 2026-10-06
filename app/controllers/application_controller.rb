class ApplicationController < ActionController::API
  before_action :set_active_storage_url_options

  include Pagy::Method
  include Devise::Controllers::Helpers
  include Pundit::Authorization

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

  def set_active_storage_url_options
    ActiveStorage::Current.url_options = {
      host: request.host,
      protocol: request.protocol,
      port: request.optional_port
    }
  end

  def render_success(data:, meta: {}, status: :ok)
    render json: { data:, meta:, errors: [] }, status:
  end

  def render_error(code:, message:, field: nil, status: :unprocessable_content)
    render json: {
      data: nil,
      meta: {},
      errors: [
        {
          code:,
          field:,
          message:
        }.compact
      ]
    }, status:
  end

  def paginate_collection(scope)
    pagy(scope, page: params[:page], limit: params[:per_page])
  end

  def pagination_meta(pagination, extra = {})
    {
      count: pagination.count,
      page: pagination.page,
      per_page: pagination.limit,
      pages: pagination.last,
      next_page: pagination.next,
      previous_page: pagination.previous
    }.merge(extra)
  end

  def render_forbidden
    render_error(
      code: "forbidden",
      message: "You are not allowed to perform this action.",
      status: :forbidden
    )
  end

  def render_not_found
    render_error(
      code: "not_found",
      message: "The requested resource was not found.",
      status: :not_found
    )
  end

  def render_record_invalid(error)
    render json: {
      data: nil,
      meta: {},
      errors: error.record.errors.map do |record_error|
        {
          code: "validation_error",
          field: record_error.attribute,
          message: record_error.full_message
        }
      end
    }, status: :unprocessable_content
  end
end
