class PurgeAttachmentJob < ApplicationJob
  queue_as :default

  def perform(attachment_id, record_type, record_id, name)
    attachment = ActiveStorage::Attachment.find_by(id: attachment_id)
    return unless attachment

    attachment.purge
    AuditLog.create!(
      action: "attachment.purged",
      auditable_type: record_type,
      auditable_id: record_id,
      changeset: { "attachment_id" => attachment_id, "name" => name }
    )
  end
end
