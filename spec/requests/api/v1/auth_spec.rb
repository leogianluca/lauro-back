require "rails_helper"

RSpec.describe "API authentication", type: :request do
  describe "POST /api/v1/auth/login" do
    it "returns a JWT and the user profile" do
      user = create(:user, :admin, email: "admin@example.com", password: "password123")

      post "/api/v1/auth/login", params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to be_present
      expect(json_response.dig("data", "token")).to be_present
      expect(json_response.dig("data", "email")).to eq("admin@example.com")
      expect(json_response.dig("data", "role")).to eq("admin")
      expect(json_response.dig("data", "permissions")).to include("users:manage")
      expect(json_response["errors"]).to eq([])
    end
  end

  describe "GET /api/v1/me" do
    it "requires authentication" do
      get "/api/v1/me"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the current user profile and permissions" do
      user = create(:user, :editor, name: "Editor User")

      get "/api/v1/me", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(json_response.dig("data", "name")).to eq("Editor User")
      expect(json_response.dig("data", "role")).to eq("editor")
      expect(json_response.dig("data", "permissions")).to include("content:manage")
      expect(json_response.dig("data", "permissions")).not_to include("users:manage")
    end
  end
end
