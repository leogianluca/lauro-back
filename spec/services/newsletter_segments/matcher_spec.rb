require "rails_helper"

RSpec.describe NewsletterSegments::Matcher, type: :service do
  it "matches canonical consent and source fields" do
    matching = create(:newsletter_subscriber, source: "landing", metadata: { "city" => "Miami" })
    create(:newsletter_subscriber, source: "partner", metadata: { "city" => "Miami" })
    segment = NewsletterSegment.create!(name: "Consentidos", conditions: [
      { "field" => "source", "operator" => "equals", "value" => "landing" },
      { "field" => "consent", "operator" => "equals", "value" => "true" }
    ])

    expect(described_class.new(segment).scope).to contain_exactly(matching)
  end

  it "supports OR logic" do
    first = create(:newsletter_subscriber, metadata: { "city" => "Miami" })
    second = create(:newsletter_subscriber, metadata: { "city" => "Orlando" })
    segment = NewsletterSegment.create!(name: "Duas cidades", logic: "or", conditions: [
      { "field" => "city", "operator" => "equals", "value" => "Miami" },
      { "field" => "city", "operator" => "equals", "value" => "Orlando" }
    ])

    expect(described_class.new(segment).scope).to contain_exactly(first, second)
  end
end
