module Api
  module V1
    class HealthController < ApplicationController
      def show
        checks = {
          database: database_check,
          storage: storage_check,
          queue: queue_check
        }
        status = checks.values.all? ? :ok : :service_unavailable
        render_success(data: { status: status == :ok ? "ok" : "degraded", checks: }, status:)
      end

      private

      def database_check
        ActiveRecord::Base.connection.select_value("SELECT 1") == 1
      rescue StandardError
        false
      end

      def storage_check
        ActiveStorage::Blob.service.exist?("health-check") || ActiveStorage::Blob.service.name.present?
      rescue StandardError
        false
      end

      def queue_check
        adapter = ActiveJob::Base.queue_adapter
        return false unless adapter.present?
        return true unless adapter.class.name.to_s.include?("SolidQueue")
        return false unless defined?(SolidQueue::Job)

        SolidQueue::Job.connection.select_value("SELECT 1") == 1
      rescue StandardError
        false
      end
    end
  end
end
