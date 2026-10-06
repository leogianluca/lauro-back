require "rails_helper"

RSpec.describe "Admin content pages", type: :request do
  it "keeps reading, editing, and changing visibility on separate routes" do
    viewer = create(:user, :viewer)
    editor = create(:user, :editor)
    page = create(:content_page, visibility: :private)

    get "/api/v1/admin/content_pages/#{page.id}", headers: auth_headers_for(viewer)
    expect(response).to have_http_status(:ok)
    expect(page.reload).to be_visibility_private

    patch "/api/v1/admin/content_pages/#{page.id}",
      params: { content_page: { title: "Updated content page" } },
      headers: auth_headers_for(editor)
    expect(response).to have_http_status(:ok)
    expect(page.reload.title).to eq("Updated content page")
    expect(page).to be_visibility_private

    patch "/api/v1/admin/content_pages/#{page.id}/show", headers: auth_headers_for(viewer)
    expect(response).to have_http_status(:forbidden)
    expect(page.reload).to be_visibility_private

    patch "/api/v1/admin/content_pages/#{page.id}/show", headers: auth_headers_for(editor)
    expect(response).to have_http_status(:ok)
    expect(page.reload).to be_visibility_public
  end

  it "allows an editor to create and publish a page" do
    editor = create(:user, :editor)

    post "/api/v1/admin/content_pages",
         params: { content_page: attributes_for(:content_page, title: "Investment Strategy") },
         headers: auth_headers_for(editor)

    expect(response).to have_http_status(:created)
    page = ContentPage.find(json_response.dig("data", "id"))

    patch "/api/v1/admin/content_pages/#{page.id}/publish", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:ok)
    expect(page.reload).to be_published
  end

  it "rejects a viewer from creating a page" do
    viewer = create(:user, :viewer)

    post "/api/v1/admin/content_pages",
         params: { content_page: attributes_for(:content_page) },
         headers: auth_headers_for(viewer)

    expect(response).to have_http_status(:forbidden)
  end
end
