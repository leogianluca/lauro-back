namespace :production do
  desc "Validate production configuration without contacting external providers"
  task check: :environment do
    required = %w[DATABASE_URL DEVISE_JWT_SECRET_KEY CORS_ORIGINS APP_PUBLIC_URL NEWSLETTER_WEBHOOK_SECRET]
    required += %w[AWS_REGION AWS_S3_BUCKET] if ENV.fetch("ACTIVE_STORAGE_SERVICE", "amazon") == "amazon"
    required += %w[SMTP_ADDRESS SMTP_USERNAME SMTP_PASSWORD MAILER_FROM] if ENV.fetch("MAILER_DELIVERY_METHOD", "smtp") == "smtp"

    missing = required.select { |name| ENV[name].to_s.strip.empty? }
    abort "Missing production environment variables: #{missing.join(", ")}" if missing.any?
    abort "APP_PUBLIC_URL must use HTTPS in production." unless ENV.fetch("APP_PUBLIC_URL").start_with?("https://")
    abort "CORS_ORIGINS must be explicit and cannot contain '*'." if ENV.fetch("CORS_ORIGINS").split(",").map(&:strip).include?("*")
    abort "DEVISE_JWT_SECRET_KEY must not use the development placeholder." if ENV.fetch("DEVISE_JWT_SECRET_KEY").include?("change-me")
    abort "NEWSLETTER_WEBHOOK_SECRET must be at least 32 characters." if ENV.fetch("NEWSLETTER_WEBHOOK_SECRET").length < 32

    puts "Production configuration preflight passed."
  end
end
