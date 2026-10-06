require "rails_helper"

RSpec.describe "role permissions", type: :model do
  it "keeps admin permissions broad" do
    user = build(:user, :admin)

    expect(user.permissions).to include("users:manage", "settings:manage", "media:manage")
  end

  it "keeps editor permissions focused on content operations" do
    user = build(:user, :editor)

    expect(user.permissions).to include("investment_cards:manage", "content:manage")
    expect(user.permissions).not_to include("users:manage")
  end

  it "keeps viewer permissions read-only" do
    user = build(:user, :viewer)

    expect(user.permissions).to all(end_with(":read"))
  end
end
