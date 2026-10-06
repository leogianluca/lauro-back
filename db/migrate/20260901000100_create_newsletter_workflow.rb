class CreateNewsletterWorkflow < ActiveRecord::Migration[8.1]
  def change
    create_table :newsletter_contents, id: :uuid do |t|
      t.string :title, null: false
      t.string :content_type, null: false
      t.string :category
      t.string :status, null: false, default: "draft"
      t.text :subtitle
      t.text :description
      t.string :cta_label
      t.string :cta_url
      t.jsonb :metadata, null: false, default: {}
      t.datetime :published_at
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :newsletter_contents, :content_type
    add_index :newsletter_contents, :status
    add_index :newsletter_contents, :discarded_at

    create_table :newsletter_templates, id: :uuid do |t|
      t.string :name, null: false
      t.string :status, null: false, default: "draft"
      t.jsonb :blocks, null: false, default: []
      t.jsonb :branding, null: false, default: {}
      t.boolean :favorite, null: false, default: false
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :newsletter_templates, :status
    add_index :newsletter_templates, :discarded_at

    create_table :newsletter_segments, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.jsonb :conditions, null: false, default: []
      t.integer :contacts_count, null: false, default: 0
      t.string :status, null: false, default: "active"
      t.timestamps
    end

    create_table :newsletter_edition_segments, id: :uuid do |t|
      t.references :newsletter_edition, type: :uuid, null: false, foreign_key: true
      t.references :newsletter_segment, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end
    add_index :newsletter_edition_segments, [ :newsletter_edition_id, :newsletter_segment_id ], unique: true, name: "idx_edition_segments_unique"

    create_table :newsletter_edition_versions, id: :uuid do |t|
      t.references :newsletter_edition, type: :uuid, null: false, foreign_key: true
      t.references :created_by, type: :uuid, foreign_key: { to_table: :users }
      t.integer :version_number, null: false
      t.jsonb :snapshot, null: false, default: {}
      t.text :change_note
      t.timestamps
    end
    add_index :newsletter_edition_versions, [ :newsletter_edition_id, :version_number ], unique: true, name: "idx_edition_versions_unique"

    create_table :newsletter_approval_comments, id: :uuid do |t|
      t.references :newsletter_edition, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.text :body, null: false
      t.string :status, null: false, default: "open"
      t.timestamps
    end

    create_table :newsletter_metric_events, id: :uuid do |t|
      t.references :newsletter_edition, type: :uuid, null: false, foreign_key: true
      t.references :newsletter_delivery, type: :uuid, foreign_key: true
      t.string :event_type, null: false
      t.string :recipient_email
      t.string :link_url
      t.datetime :occurred_at, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :newsletter_metric_events, [ :newsletter_edition_id, :event_type ], name: "idx_newsletter_metrics_lookup"
  end
end
