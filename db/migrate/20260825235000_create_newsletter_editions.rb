class CreateNewsletterEditions < ActiveRecord::Migration[8.1]
  def change
    create_table :newsletter_editions, id: :uuid do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :excerpt
      t.text :body
      t.string :status, null: false, default: "draft"
      t.string :visibility, null: false, default: "public"
      t.datetime :published_at
      t.datetime :discarded_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :newsletter_editions, :slug, unique: true
    add_index :newsletter_editions, :status
    add_index :newsletter_editions, :visibility
    add_index :newsletter_editions, :published_at
    add_index :newsletter_editions, :discarded_at
  end
end
