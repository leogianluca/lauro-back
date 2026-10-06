require "rails_helper"

RSpec.describe User, type: :model do
  it "defaults to viewer role" do
    user = described_class.new(email: "viewer@example.com", password: "password123")
    user.validate

    expect(user.role).to eq("viewer")
  end

  it "assigns a JTI before validation" do
    user = described_class.new(email: "viewer@example.com", password: "password123")
    user.validate

    expect(user.jti).to be_present
  end
end
