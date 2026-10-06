module Attachments
  class Purge
    ALLOWED_NAMES = %w[cover_image gallery_images documents images].freeze

    def initialize(record, name:, attachment_id:, user: nil)
      @record = record
      @name = name.to_s
      @attachment_id = attachment_id
      @user = user
    end

    def call
      raise ActiveRecord::RecordNotFound unless ALLOWED_NAMES.include?(@name)

      attachment = @record.public_send(@name).attachments.find(@attachment_id)
      AuditLog.create!(
        user: @user,
        action: "attachment.purge_requested",
        auditable_type: @record.class.base_class.name,
        auditable_id: @record.id,
        changeset: { "attachment_id" => attachment.id, "name" => @name, "filename" => attachment.filename.to_s }
      )
      PurgeAttachmentJob.perform_later(attachment.id, @record.class.name, @record.id, @name)
      attachment
    end
  end
end
