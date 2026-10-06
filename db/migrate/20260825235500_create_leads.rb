class CreateLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :leads, id: :uuid do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :source
      t.string :status, null: false, default: "new"
      t.text :message
      t.datetime :consented_at
      t.jsonb :metadata, null: false, default: {}
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :leads, :email
    add_index :leads, :status
    add_index :leads, :source
    add_index :leads, :discarded_at
  end
end
