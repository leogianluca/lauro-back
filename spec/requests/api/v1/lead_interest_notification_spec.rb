require "rails_helper"

RSpec.describe "Card interest notification", type: :request do
  include ActiveJob::TestHelper

  it "saves the selected listing and queues a notification with the visitor as reply-to" do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("LEAD_INTEREST_EMAIL_ENABLED", "false").and_return("true")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("LEAD_NOTIFICATION_EMAIL").and_return("team@example.test")
    card = create(:investment_card, :published)
    perform_enqueued_jobs do
      post "/api/v1/leads", params: {
        consent: true, lead: { name: "Maria", email: "maria@example.test", source: "deal_interest", investment_card_id: card.id, message: "Please contact me." }
      }
    end
    expect(response).to have_http_status(:created)
    expect(Lead.last.investment_card_id).to eq(card.id)
    delivery = ActionMailer::Base.deliveries.last
    expect(delivery.to).to eq([ "team@example.test" ])
    expect(delivery.reply_to).to eq([ "maria@example.test" ])
    expect(delivery.subject).to include(card.title)
    expect(delivery.body.decoded).to include("Please contact me.")
  end

  it "saves contact details without queuing email by default, even with a recipient configured" do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("LEAD_INTEREST_EMAIL_ENABLED", "false").and_return("false")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("LEAD_NOTIFICATION_EMAIL").and_return("team@example.test")
    card = create(:investment_card, :published)

    expect do
      post "/api/v1/leads", params: {
        consent: true, lead: { name: "Maria", email: "maria@example.test", phone: "+1 561 555 0123", source: "deal_interest", investment_card_id: card.id, message: "Please contact me." }
      }
    end.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)

    expect(response).to have_http_status(:created)
    expect(Lead.last).to have_attributes(investment_card_id: card.id, name: "Maria", email: "maria@example.test", phone: "+1 561 555 0123", message: "Please contact me.")
  end
end
