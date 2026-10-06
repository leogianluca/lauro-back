class AddUniqueIndexToNewsletterSubscribersEmail < ActiveRecord::Migration[8.1]
  def change
    add_index :newsletter_subscribers, :email, unique: true, name: "idx_newsletter_subscribers_email_unique"
  end
end
