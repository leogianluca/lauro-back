class Rack::Attack
  throttle("api/ip", limit: 300, period: 5.minutes) do |request|
    request.ip if request.path.start_with?("/api/")
  end

  throttle("auth/login/ip", limit: 10, period: 1.minute) do |request|
    request.ip if request.post? && request.path == "/api/v1/auth/login"
  end

  throttle("public/leads/ip", limit: 20, period: 1.minute) do |request|
    request.ip if request.post? && request.path == "/api/v1/leads"
  end

  throttle("public/subscribers/ip", limit: 20, period: 1.minute) do |request|
    request.ip if request.post? && request.path == "/api/v1/newsletter_subscribers"
  end

  throttle("public/metrics/ip", limit: 120, period: 1.minute) do |request|
    request.ip if request.post? && request.path.start_with?("/api/v1/newsletter_metric_events")
  end

  self.throttled_responder = lambda do |_request|
    [
      429,
      { "Content-Type" => "application/json" },
      [
        {
          data: nil,
          meta: {},
          errors: [
            {
              code: "rate_limited",
              message: "Too many requests. Please try again later."
            }
          ]
        }.to_json
      ]
    ]
  end
end
