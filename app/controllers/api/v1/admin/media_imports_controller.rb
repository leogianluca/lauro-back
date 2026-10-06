module Api
  module V1
    module Admin
      class MediaImportsController < BaseController
        def create
          record = attachable_record
          authorize record, :update?

          files = params[:files]
          files = if files.is_a?(Array)
            files.compact.reject(&:blank?)
          elsif files.present? && (!files.respond_to?(:empty?) || !files.empty?)
            [ files ]
          else
            []
          end
          kind = params[:kind].to_s
          return render_error(code: "invalid_media_import", message: "At least one file is required.", status: :unprocessable_content) if files.empty?
          return render_error(code: "invalid_media_kind", message: "Kind must be gallery_image or document.", status: :unprocessable_content) unless MediaImportItem.kinds.key?(kind)

          batch = MediaImportBatch.transaction do
            import_batch = record.media_import_batches.create!(total_items: files.size)
            files.each_with_index do |file, index|
              item = import_batch.items.create!(kind:, position: index + 1)
              item.file.attach(file)
            end
            import_batch
          end

          ProcessMediaImportBatchJob.perform_later(batch.id)
          render_success(data: MediaImportBatchBlueprint.render_as_hash(batch), status: :accepted)
        end

        def show
          batch = MediaImportBatch.find(params[:id])
          authorize batch.investment_card || batch.newsletter_edition, :update?
          render_success(data: MediaImportBatchBlueprint.render_as_hash(batch))
        end

        def retry
          batch = MediaImportBatch.find(params[:id])
          authorize batch.investment_card || batch.newsletter_edition, :update?
          retryable_items = batch.items.retryable
          return render_error(code: "retry_limit_reached", message: "All failed files have exhausted their retry limit.", status: :conflict) if retryable_items.none?

          retryable_items.update_all(status: MediaImportItem.statuses.fetch("pending"), error_message: nil)
          batch.update!(status: :pending, finished_at: nil)
          ProcessMediaImportBatchJob.perform_later(batch.id)
          render_success(data: MediaImportBatchBlueprint.render_as_hash(batch), status: :accepted)
        end

        private

        def attachable_record
          if params[:investment_card_id].present?
            InvestmentCard.kept.find(params[:investment_card_id])
          else
            NewsletterEdition.kept.find(params[:newsletter_edition_id])
          end
        end
      end
    end
  end
end
