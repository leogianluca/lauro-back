require "rails_helper"

RSpec.describe NewsletterCampaigns::LinkTracker, type: :service do
  it "rewrites HTTP links to signed tracking links" do
    delivery = create(:newsletter_delivery)

    html = described_class.new('<a href="https://example.com/property">View</a>', delivery).call

    expect(html).to include("/api/v1/newsletter_tracking/")
    expect(html).not_to include("href=\"https://example.com/property\"")
  end
end
