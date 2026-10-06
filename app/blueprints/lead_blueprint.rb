class LeadBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :email, :phone, :source, :status, :message, :consented_at, :investment_card_id,
         :assigned_to_id, :internal_notes,
         :metadata, :created_at, :updated_at
end
