require "rails_helper"

RSpec.describe NewsletterSegment, type: :model do
  it "accepts structured conditions" do
    segment = described_class.new(
      name: "Investidores de Miami",
      conditions: [
        { "field" => "city", "operator" => "equals", "value" => "Miami" },
        { "field" => "consent", "operator" => "equals", "value" => true }
      ]
    )

    expect(segment).to be_valid
  end

  it "rejects unknown fields and operators" do
    segment = described_class.new(
      name: "Segmento inválido",
      conditions: [ { "field" => "password", "operator" => "exec", "value" => "x" } ]
    )

    expect(segment).not_to be_valid
    expect(segment.errors[:conditions].join).to include("invalid field")
    expect(segment.errors[:conditions].join).to include("invalid operator")
  end
end
