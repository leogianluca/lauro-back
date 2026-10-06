require "rails_helper"

RSpec.describe "Health", type: :request do
  describe "GET /api/v1/health" do
    it "returns the status and infrastructure checks" do
      get "/api/v1/health"

      expect(response).to have_http_status(:ok)
      expect(json_response).to include(
        "data" => include(
          "status" => "ok",
          "checks" => {
            "database" => true,
            "storage" => true,
            "queue" => true
          }
        ),
        "meta" => {},
        "errors" => []
      )
    end

    it "allows the public frontend development origin on port 8081" do
      get "/api/v1/health", headers: { "Origin" => "http://localhost:8081" }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Access-Control-Allow-Origin"]).to eq("http://localhost:8081")
    end
  end
end
