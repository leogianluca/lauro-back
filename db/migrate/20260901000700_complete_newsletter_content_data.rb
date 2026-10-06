class CompleteNewsletterContentData < ActiveRecord::Migration[8.1]
  def change
    change_table :newsletter_contents do |t|
      t.string :slug
      t.string :alt_text
      t.jsonb :tags, null: false, default: []
      t.date :event_date
      t.time :event_time
      t.string :event_timezone
      t.string :event_location
      t.string :registration_url
      t.uuid :investment_card_id
    end
    add_index :newsletter_contents, :slug, unique: true
    add_index :newsletter_contents, :investment_card_id
    add_foreign_key :newsletter_contents, :investment_cards
  end
end
