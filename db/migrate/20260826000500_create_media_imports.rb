class CreateMediaImports < ActiveRecord::Migration[8.1]
  def change
    create_table :media_import_batches, id: :uuid do |t|
      t.references :investment_card, type: :uuid, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.integer :total_items, null: false, default: 0
      t.integer :processed_items, null: false, default: 0
      t.integer :failed_items, null: false, default: 0
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps
    end

    create_table :media_import_items, id: :uuid do |t|
      t.references :media_import_batch, type: :uuid, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.integer :position
      t.text :error_message
      t.datetime :processed_at
      t.timestamps
    end

    add_index :media_import_batches, :status
    add_index :media_import_items, :status
  end
end
