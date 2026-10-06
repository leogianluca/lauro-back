class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs, id: :uuid do |t|
      t.references :user, type: :uuid, foreign_key: true
      t.string :action, null: false
      t.string :auditable_type, null: false
      t.uuid :auditable_id, null: false
      t.jsonb :changeset, null: false, default: {}
      t.string :ip_address
      t.string :request_id
      t.timestamps
    end

    add_index :audit_logs, %i[auditable_type auditable_id]
    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
  end
end
