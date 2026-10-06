require "rails_helper"

RSpec.describe NewsletterCampaigns::Compose do
  it "starts from the template blocks" do
    template = NewsletterTemplate.create!(name: "Base", blocks: [ { "type" => "hero", "title" => "Base" } ])
    edition = create(:newsletter_edition, metadata: { "template_id" => template.id })

    described_class.new(edition).call

    expect(edition.reload.metadata["blocks"]).to eq(template.blocks)
  end

  it "keeps campaign-specific block edits" do
    template = NewsletterTemplate.create!(name: "Base", blocks: [ { "type" => "hero", "title" => "Base" } ])
    custom_blocks = [ { "id" => "custom", "type" => "text", "title" => "Editado", "content" => "Texto" } ]
    edition = create(:newsletter_edition, metadata: { "template_id" => template.id, "blocks" => custom_blocks, "blocks_customized" => true })

    described_class.new(edition).call

    expect(edition.reload.metadata["blocks"]).to eq(custom_blocks)
  end
end
