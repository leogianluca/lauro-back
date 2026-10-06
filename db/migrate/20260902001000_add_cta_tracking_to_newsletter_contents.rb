class AddCtaTrackingToNewsletterContents < ActiveRecord::Migration[8.1]
  def change
    change_table :newsletter_contents do |t|
      t.string :cta_target, null: false, default: "_self"
      t.string :tracking_key
    end
    add_index :newsletter_contents, :tracking_key
  end
end
