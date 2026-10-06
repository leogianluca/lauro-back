class AddAttemptsToNewsletterDeliveries < ActiveRecord::Migration[8.1]
  def change
    add_column :newsletter_deliveries, :attempts, :integer, null: false, default: 0
    add_column :newsletter_deliveries, :last_attempt_at, :datetime
    add_index :newsletter_deliveries, :attempts
  end
end
