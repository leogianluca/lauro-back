class CreateNewsletterTemplateVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :newsletter_template_versions, id: :uuid do |t|
      t.references :newsletter_template, null: false, type: :uuid, foreign_key: true
      t.references :created_by, null: true, type: :uuid, foreign_key: { to_table: :users }
      t.integer :version_number, null: false
      t.jsonb :snapshot, null: false, default: {}
      t.text :change_note
      t.timestamps
    end

    add_index :newsletter_template_versions, [ :newsletter_template_id, :version_number ], unique: true, name: "idx_template_versions_unique"
  end
end
