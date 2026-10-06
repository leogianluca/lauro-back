class AddConsentedAtToNewsletterSubscribers < ActiveRecord::Migration[8.1]
  def change
    add_column :newsletter_subscribers, :consented_at, :datetime
  end
end
