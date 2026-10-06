abort "E2E fixture may only run in the test environment" unless Rails.env.test?

email = ENV.fetch("E2E_ADMIN_EMAIL")
password = ENV.fetch("E2E_ADMIN_PASSWORD")
abort "Use a dedicated E2E email" unless email.end_with?("@localhost.invalid")

case ARGV.fetch(0)
when "setup"
  user = User.find_or_initialize_by(email: email)
  user.assign_attributes(name: "E2E Admin", role: :admin, password: password)
  user.save!
  puts "E2E test administrator ready"
when "cleanup"
  User.find_by(email: email)&.destroy!
  puts "E2E test administrator removed"
else
  abort "Expected setup or cleanup"
end
