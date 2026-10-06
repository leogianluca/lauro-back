class CreateNewsletterDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :newsletter_deliveries, id: :uuid do |t|
      t.references :newsletter_edition, type: :uuid, null: false, foreign_key: true
      t.references :newsletter_subscriber, type: :uuid, null: false, foreign_key: true
      t.string :status, null: false, default: "queued"
      t.datetime :sent_at
      t.text :error_message
      t.timestamps
    end

    add_index :newsletter_deliveries, [ :newsletter_edition_id, :newsletter_subscriber_id ], unique: true, name: "index_newsletter_deliveries_on_edition_and_subscriber"
    add_index :newsletter_deliveries, :status
  end
end
