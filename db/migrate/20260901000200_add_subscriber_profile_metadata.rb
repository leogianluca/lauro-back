class AddSubscriberProfileMetadata < ActiveRecord::Migration[8.1]
  def change
    add_column :newsletter_subscribers, :metadata, :jsonb, null: false, default: {}
    add_index :newsletter_subscribers, :metadata, using: :gin
  end
end
