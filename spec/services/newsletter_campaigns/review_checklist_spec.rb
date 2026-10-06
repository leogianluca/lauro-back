require "rails_helper"

RSpec.describe NewsletterCampaigns::ReviewChecklist do
  it "validates the rendered campaign requirements" do
    create(:newsletter_subscriber)
    edition = create(:newsletter_edition, body: "https://example.com", metadata: { "subject" => "Market", "preheader" => "Highlights" })

    checklist = described_class.new(edition).call

    expect(checklist).to include(
      subject: true,
      preheader: true,
      content: true,
      links: true,
      unsubscribe: true,
      mobile: true,
      audience: true
    )
  end

  it "rejects a campaign without subject, preheader or audience" do
    edition = create(:newsletter_edition, body: "No metadata")

    checklist = described_class.new(edition).call

    expect(checklist).to include(subject: false, preheader: false, audience: false)
  end
end
