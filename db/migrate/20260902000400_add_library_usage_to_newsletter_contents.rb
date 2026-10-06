class AddLibraryUsageToNewsletterContents < ActiveRecord::Migration[8.1]
  def change
    add_column :newsletter_contents, :favorite, :boolean, null: false, default: false
    add_column :newsletter_contents, :used_count, :integer, null: false, default: 0
    add_column :newsletter_contents, :last_used_at, :datetime
    add_index :newsletter_contents, :favorite
    add_index :newsletter_contents, :last_used_at
  end
end
