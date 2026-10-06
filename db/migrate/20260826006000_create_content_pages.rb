class CreateContentPages < ActiveRecord::Migration[8.1]
  def change
    create_table :content_pages, id: :uuid do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :page_type, null: false, default: "institutional"
      t.string :eyebrow
      t.text :excerpt
      t.text :body
      t.string :status, null: false, default: "draft"
      t.string :visibility, null: false, default: "public"
      t.datetime :published_at
      t.datetime :discarded_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :content_pages, :slug, unique: true
    add_index :content_pages, :page_type
    add_index :content_pages, :status
    add_index :content_pages, :visibility
    add_index :content_pages, :discarded_at
  end
end
