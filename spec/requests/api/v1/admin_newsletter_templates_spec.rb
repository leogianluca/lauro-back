require "rails_helper"

RSpec.describe "Admin newsletter templates", type: :request do
  it "creates a snapshot before updating and restores it" do
    editor = create(:user, :editor)
    template = NewsletterTemplate.create!(name: "Editorial", blocks: [ { "type" => "hero" } ])

    patch "/api/v1/admin/newsletter_templates/#{template.id}",
          params: { newsletter_template: { name: "Editorial atualizado" } },
          headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    version = template.reload.newsletter_template_versions.first
    expect(version.snapshot["name"]).to eq("Editorial")

    post "/api/v1/admin/newsletter_templates/#{template.id}/restore_version",
         params: { version_id: version.id },
         headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(template.reload.name).to eq("Editorial")
  end

  it "lists template versions for authorized users" do
    editor = create(:user, :editor)
    template = NewsletterTemplate.create!(name: "Editorial")
    template.newsletter_template_versions.create!(created_by: editor, version_number: 1, snapshot: { "name" => "Editorial" })

    get "/api/v1/admin/newsletter_templates/#{template.id}/versions", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(json_response.fetch("data").size).to eq(1)
  end

  it "renders a safe preview for a saved template" do
    editor = create(:user, :editor)
    template = NewsletterTemplate.create!(name: "Editorial", blocks: [ { "type" => "hero", "title" => "Destaque", "content" => "javascript:alert(1)" } ])

    get "/api/v1/admin/newsletter_templates/#{template.id}/preview", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "html")).to include("Editorial", "Destaque")
    expect(json_response.dig("data", "html")).not_to match(/(?:href|src)=\\"javascript:/i)
  end

  it "keeps a single default template" do
    editor = create(:user, :editor)
    first = NewsletterTemplate.create!(name: "Primeiro", default_template: true)
    second = NewsletterTemplate.create!(name: "Segundo")

    patch "/api/v1/admin/newsletter_templates/#{second.id}/make_default", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(first.reload.default_template).to be(false)
    expect(second.reload.default_template).to be(true)
  end
end
