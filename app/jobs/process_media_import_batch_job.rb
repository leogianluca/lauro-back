class ProcessMediaImportBatchJob < ApplicationJob
  queue_as :default

  def perform(batch_id)
    MediaImports::ProcessBatch.new(MediaImportBatch.find(batch_id)).call
  end
end
