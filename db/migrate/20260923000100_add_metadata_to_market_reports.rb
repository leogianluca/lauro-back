class AddMetadataToMarketReports < ActiveRecord::Migration[8.1]
  def change
    add_column :market_reports, :metadata, :jsonb, null: false, default: {}
  end
end
