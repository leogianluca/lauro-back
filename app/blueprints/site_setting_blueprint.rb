class SiteSettingBlueprint < Blueprinter::Base
  identifier :id

  fields :key, :value, :category, :public, :description, :created_at, :updated_at
end
