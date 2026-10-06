require "rails_helper"

RSpec.describe "Admin site settings", type: :request do
  it "allows an admin to create a setting" do
    admin = create(:user, :admin)

    post "/api/v1/admin/site_settings",
         params: {
           site_setting: {
             key: "contact.whatsapp",
             category: "contact",
             public: true,
             value: { number: "+1 407 555 0100" }
           }
         },
         headers: auth_headers_for(admin)

    expect(response).to have_http_status(:created)
    expect(SiteSetting.last.value["number"]).to eq("+1 407 555 0100")
  end

  it "rejects an editor from managing settings" do
    editor = create(:user, :editor)

    get "/api/v1/admin/site_settings", headers: auth_headers_for(editor)

    expect(response).to have_http_status(:forbidden)
  end
end
