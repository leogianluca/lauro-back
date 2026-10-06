class HardenNewsletterMetricEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :newsletter_metric_events, :idempotency_key, :string
    add_index :newsletter_metric_events, :idempotency_key, unique: true
  end
end
