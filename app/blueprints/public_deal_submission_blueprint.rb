class PublicDealSubmissionBlueprint < Blueprinter::Base
  identifier :id

  fields :status, :created_at

  field :images_count do |submission|
    submission.images.attachments.size
  end

  field :documents_count do |submission|
    submission.documents.attachments.size
  end
end
