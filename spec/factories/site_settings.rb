FactoryBot.define do
  factory :site_setting do
    sequence(:key) { |number| "setting_#{number}" }
    value { { enabled: true } }
    category { "general" }
    public { false }
    description { "A configurable platform setting." }
  end
end
