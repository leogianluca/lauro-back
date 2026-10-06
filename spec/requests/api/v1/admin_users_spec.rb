require "rails_helper"

RSpec.describe "Admin users", type: :request do
  it "allows an admin to list users" do
    admin = create(:user, :admin)
    create(:user, :editor)

    get "/api/v1/admin/users", headers: auth_headers_for(admin)

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("meta", "count")).to eq(2)
  end

  it "allows an admin to change a user's role" do
    admin = create(:user, :admin)
    user = create(:user, :viewer)

    patch "/api/v1/admin/users/#{user.id}",
          params: { user: { role: "editor", name: "Content Editor" } },
          headers: auth_headers_for(admin)

    expect(response).to have_http_status(:ok)
    expect(user.reload.role).to eq("editor")
    expect(json_response.dig("data", "permissions")).to include("content:manage")
  end

  it "does not allow an editor to manage users" do
    editor = create(:user, :editor)

    get "/api/v1/admin/users", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:forbidden)
  end
end
