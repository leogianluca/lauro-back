require "rails_helper"

RSpec.describe PurgeAttachmentJob, type: :job do
  include ActiveJob::TestHelper

  it "purges the attachment and records completion" do
    card = create(:investment_card)
    card.documents.attach(io: StringIO.new("%PDF-1.4"), filename: "memo.pdf", content_type: "application/pdf")
    attachment = card.documents.attachments.first

    described_class.perform_now(attachment.id, "InvestmentCard", card.id, "documents")

    expect(ActiveStorage::Attachment.exists?(attachment.id)).to be(false)
    expect(AuditLog.where(action: "attachment.purged", auditable_id: card.id)).to exist
  end
end
