require "rails_helper"

RSpec.describe DeliverNewsletterCampaignJob, type: :job do
  include ActiveJob::TestHelper

  it "does not fall back to a live segment when the frozen audience is empty" do
    edition = create(:newsletter_edition, :published, metadata: { "audience_snapshot" => [], "subject" => "Empty" })
    subscriber = create(:newsletter_subscriber)

    described_class.perform_now(edition.id, nil)

    expect(subscriber.newsletter_deliveries).to be_empty
    expect(edition.reload).to be_sent
  end

  it "retries a failed delivery up to the configured limit" do
    edition = create(:newsletter_edition, :published, metadata: { "audience_snapshot" => [], "subject" => "Retry" })
    subscriber = create(:newsletter_subscriber)
    edition.update!(metadata: edition.metadata.merge("audience_snapshot" => [ subscriber.id ]))
    mail = instance_double(ActionMailer::MessageDelivery)
    allow(NewsletterMailer).to receive(:with).and_return(double(edition: mail))
    allow(mail).to receive(:deliver_now).and_raise(StandardError, "provider unavailable")

    described_class.perform_now(edition.id, nil)

    delivery = edition.newsletter_deliveries.find_by!(newsletter_subscriber: subscriber)
    expect(delivery).to be_failed
    expect(delivery.attempts).to eq(NewsletterDelivery::MAX_ATTEMPTS)
    expect(mail).to have_received(:deliver_now).exactly(NewsletterDelivery::MAX_ATTEMPTS).times
  end

  it "does not retry an already exhausted delivery" do
    edition = create(:newsletter_edition, :published, metadata: { "audience_snapshot" => [] })
    subscriber = create(:newsletter_subscriber)
    delivery = edition.newsletter_deliveries.create!(newsletter_subscriber: subscriber, status: :failed, attempts: NewsletterDelivery::MAX_ATTEMPTS)
    edition.update!(metadata: edition.metadata.merge("audience_snapshot" => [ subscriber.id ]))

    expect(NewsletterMailer).not_to receive(:with)
    described_class.perform_now(edition.id, nil)
    expect(delivery.reload.attempts).to eq(NewsletterDelivery::MAX_ATTEMPTS)
  end
end
