require "rails_helper"

RSpec.describe "Newsletter version restore", type: :request do
  it "restores a previous snapshot and records the operation" do
    editor = create(:user, :editor)
    edition = create(:newsletter_edition, title: "Original", body: "Original body")
    version = edition.newsletter_edition_versions.create!(created_by: editor, version_number: 1, snapshot: { "title" => "Previous", "slug" => edition.slug, "body" => "Previous body", "excerpt" => "Previous excerpt", "status" => "draft", "visibility" => "public", "metadata" => {} }, change_note: "Initial")
    edition.update!(title: "Current", body: "Current body")

    patch "/api/v1/admin/newsletter_editions/#{edition.id}/versions/#{version.id}/restore", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(edition.reload.title).to eq("Previous")
    expect(edition.body).to eq("Previous body")
    expect(edition.newsletter_edition_versions.count).to eq(3)
    expect(AuditLog.where(action: "newsletter_edition.version_restored").count).to eq(1)
  end
end
