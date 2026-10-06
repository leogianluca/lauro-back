class CreateNewsletterSubscribers < ActiveRecord::Migration[8.1]
  def change
    create_table :newsletter_subscribers, id: :uuid do |t|
      t.string :email, null: false
      t.string :source
      t.string :status, null: false, default: "subscribed"
      t.datetime :subscribed_at
      t.datetime :unsubscribed_at
      t.timestamps
    end

    add_index :newsletter_subscribers, "lower(email)", unique: true
    add_index :newsletter_subscribers, :status
  end
end
