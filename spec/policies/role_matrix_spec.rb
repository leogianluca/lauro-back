require "rails_helper"

RSpec.describe "role policy matrix" do
  POLICY_CLASSES = %w[
    ContentPagePolicy
    InvestmentCardPolicy
    MarketReportPolicy
    NewsletterContentPolicy
    NewsletterEditionPolicy
    NewsletterSegmentPolicy
    NewsletterTemplatePolicy
  ].freeze

  POLICY_CLASSES.each do |policy_name|
    it "allows #{policy_name} to follow the base role rules" do
      policy_class = policy_name.constantize
      record = policy_name.delete_suffix("Policy").constantize.new
      admin = create(:user, :admin)
      editor = create(:user, :editor)
      viewer = create(:user, :viewer)

      expect(policy_class.new(admin, record)).to be_create
      expect(policy_class.new(admin, record)).to be_update
      expect(policy_class.new(admin, record)).to be_destroy
      expect(policy_class.new(editor, record)).to be_create
      expect(policy_class.new(editor, record)).to be_update
      expect(policy_class.new(editor, record)).not_to be_destroy
      expect(policy_class.new(viewer, record)).not_to be_create
      expect(policy_class.new(viewer, record)).not_to be_update
      expect(policy_class.new(viewer, record)).not_to be_destroy
    end
  end

  it "restricts administrative records to admins" do
    admin = create(:user, :admin)
    editor = create(:user, :editor)
    viewer = create(:user, :viewer)
    setting = SiteSetting.new

    expect(SiteSettingPolicy.new(admin, setting)).to be_create
    expect(SiteSettingPolicy.new(editor, setting)).not_to be_create
    expect(SiteSettingPolicy.new(viewer, setting)).not_to be_show
    expect(AuditLogPolicy.new(admin, AuditLog.new)).to be_index
    expect(AuditLogPolicy.new(editor, AuditLog.new)).not_to be_index
  end

  it "allows users to view themselves while protecting user management" do
    admin = create(:user, :admin)
    editor = create(:user, :editor)
    viewer = create(:user, :viewer)
    policy = UserPolicy.new(viewer, viewer)

    expect(UserPolicy.new(admin, User.new)).to be_create
    expect(UserPolicy.new(editor, User.new)).not_to be_create
    expect(policy).to be_show
    expect(UserPolicy.new(viewer, User.new)).not_to be_show
  end

  it "separates newsletter review, approval, scheduling and dispatch" do
    admin = create(:user, :admin)
    editor = create(:user, :editor)
    viewer = create(:user, :viewer)
    edition = NewsletterEdition.new

    expect(NewsletterEditionPolicy.new(editor, edition)).to be_request_review
    expect(NewsletterEditionPolicy.new(editor, edition)).not_to be_approve
    expect(NewsletterEditionPolicy.new(editor, edition)).not_to be_schedule
    expect(NewsletterEditionPolicy.new(editor, edition)).to be_dispatch
    expect(NewsletterEditionPolicy.new(admin, edition)).to be_approve
    expect(NewsletterEditionPolicy.new(admin, edition)).to be_schedule
    expect(NewsletterEditionPolicy.new(viewer, edition)).not_to be_request_review
    expect(NewsletterEditionPolicy.new(viewer, edition)).not_to be_dispatch
  end
end
