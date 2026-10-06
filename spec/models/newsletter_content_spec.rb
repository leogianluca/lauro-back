require "rails_helper"

RSpec.describe NewsletterContent, type: :model do
  it "accepts supported CTA destinations and tracking keys" do
    content = NewsletterContent.new(title: "CTA", content_type: "cta", cta_label: "See more", cta_url: "https://example.com", cta_target: "_blank", tracking_key: "campaign.home-1")

    expect(content).to be_valid
  end

  it "rejects invalid CTA destinations and tracking keys" do
    content = NewsletterContent.new(title: "CTA", content_type: "cta", cta_label: "See more", cta_url: "https://example.com", cta_target: "popup", tracking_key: "campaign value")

    expect(content).not_to be_valid
    expect(content.errors[:cta_target]).to be_present
    expect(content.errors[:tracking_key]).to be_present
  end
end
