class TaxonomyTermBlueprint < Blueprinter::Base
  identifier :id

  fields :kind, :name, :slug, :description, :active, :position, :parent_id, :metadata,
         :created_at, :updated_at
end
