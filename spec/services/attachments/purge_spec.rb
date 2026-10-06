require "rails_helper"

RSpec.describe Attachments::Purge do
  include ActiveJob::TestHelper

  it "queues an attachment purge and writes an audit event" do
    card = create(:investment_card)
    card.documents.attach(io: StringIO.new("%PDF-1.4"), filename: "memo.pdf", content_type: "application/pdf")
    attachment = card.documents.attachments.first

    expect {
      described_class.new(card, name: "documents", attachment_id: attachment.id, user: create(:user, :admin)).call
    }.to have_enqueued_job(PurgeAttachmentJob).with(attachment.id, "InvestmentCard", card.id, "documents")

    expect(AuditLog.where(action: "attachment.purge_requested", auditable_id: card.id)).to exist
  end

  it "rejects an attachment name that is not exposed by the API" do
    card = create(:investment_card)

    expect {
      described_class.new(card, name: "metadata", attachment_id: SecureRandom.uuid).call
    }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
