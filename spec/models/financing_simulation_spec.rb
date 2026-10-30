require "rails_helper"

RSpec.describe "Commercial financing simulation defaults", type: :model do
  let(:card) { build(:investment_card, category: "commercial", price_cents: 900_000_000) }

  it "accepts zero interest and a cash purchase" do
    card.financing = { "interest_rate_percent" => 0, "term_years" => 30, "down_payment_cents" => 900_000_000 }
    expect(card).to be_valid
  end

  it "rejects unsafe money, excessive down payments, invalid rates and fractional terms" do
    [
      { "down_payment_cents" => 900_000_001 },
      { "down_payment_cents" => "450000000" },
      { "interest_rate_percent" => -1 },
      { "interest_rate_percent" => 101 },
      { "term_years" => 0 },
      { "term_years" => 2.5 }
    ].each do |attributes|
      card.financing = attributes
      expect(card).not_to be_valid
      expect(card.errors[:financing]).to be_present
    end
  end
end
