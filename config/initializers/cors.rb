# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    development_origins = "http://localhost:8080,http://127.0.0.1:8080,http://localhost:8081,http://127.0.0.1:8081,http://localhost:5173,http://127.0.0.1:5173"
    configured_origins = ENV["CORS_ORIGINS"].presence || (Rails.env.production? ? "" : development_origins)
    origins(*configured_origins.split(",").map(&:strip).reject(&:blank?))

    resource "*",
             headers: :any,
             expose: [ "Authorization" ],
             methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
  end
end
