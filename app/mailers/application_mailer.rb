class ApplicationMailer < ActionMailer::Base
  default from: (ENV["MAILER_FROM"].presence || "from@example.com")
  layout "mailer"
end
