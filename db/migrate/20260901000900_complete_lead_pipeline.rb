class CompleteLeadPipeline < ActiveRecord::Migration[8.1]
  def change
    add_reference :leads, :assigned_to, type: :uuid, foreign_key: { to_table: :users }, index: true
    add_column :leads, :internal_notes, :text
    add_check_constraint :leads, "status IN ('new', 'contacted', 'qualified', 'disqualified', 'converted')", name: "leads_status_allowed"
  end
end
