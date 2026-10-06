class DealSubmissionBlueprint < Blueprinter::Base
  identifier :id

  fields :submitter_name, :submitter_email, :company_name, :title, :category, :asset_type,
         :strategy, :address_line1, :city, :state, :region, :country, :zip_code,
         :price_cents, :investment_min_cents, :status, :message, :internal_notes,
         :converted_investment_card_id, :metadata, :consented_at, :created_at, :updated_at

  field :images_count do |submission|
    submission.images.attachments.size
  end

  field :documents_count do |submission|
    submission.documents.attachments.size
  end

  view :detail do
    field :attachments do |submission|
      {
        images: submission.images.attachments.map { |attachment| DealSubmissionBlueprint.attachment_details(attachment) },
        documents: submission.documents.attachments.map { |attachment| DealSubmissionBlueprint.attachment_details(attachment) }
      }
    end
  end

  def self.attachment_details(attachment)
    {
      id: attachment.id,
      filename: attachment.filename.to_s,
      content_type: attachment.blob.content_type,
      byte_size: attachment.blob.byte_size
    }
  end
end
