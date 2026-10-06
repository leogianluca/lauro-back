module AuthHelpers
  def auth_headers_for(user)
    post "/api/v1/auth/login", params: {
      user: {
        email: user.email,
        password: user.password
      }
    }

    { "Authorization" => response.headers["Authorization"] }
  end
end
