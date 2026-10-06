class CreateMarketReports < ActiveRecord::Migration[8.1]
  def change
    create_table :market_reports, id: :uuid do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :period, null: false
      t.text :excerpt
      t.text :body
      t.string :status, null: false, default: "draft"
      t.string :visibility, null: false, default: "public"
      t.datetime :published_at
      t.datetime :discarded_at
      t.jsonb :metrics, null: false, default: {}
      t.timestamps
    end

    add_index :market_reports, :slug, unique: true
    add_index :market_reports, :period
    add_index :market_reports, :status
    add_index :market_reports, :visibility
    add_index :market_reports, :published_at
    add_index :market_reports, :discarded_at
  end
end
