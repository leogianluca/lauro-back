class MediaImportBatchBlueprint < Blueprinter::Base
  identifier :id

  fields :status, :total_items, :processed_items, :failed_items, :progress,
         :started_at, :finished_at, :created_at, :updated_at

  field :items do |batch|
    batch.items.order(:position).map do |item|
      {
        id: item.id,
        kind: item.kind,
        status: item.status,
        position: item.position,
        attempts: item.attempts,
        retryable: item.attempts < MediaImportItem::MAX_ATTEMPTS,
        error_message: item.error_message,
        processed_at: item.processed_at
      }
    end
  end
end
