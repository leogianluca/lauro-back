class AddResidentialLevelTwoFields < ActiveRecord::Migration[8.1]
  def change
    change_table :investment_cards do |t|
      t.string :market_status, null: false, default: "active"
      t.decimal :down_payment_percent, precision: 6, scale: 3
      t.integer :down_payment_cents
      t.integer :living_area_sqft
      t.integer :bedrooms
      t.decimal :bathrooms, precision: 5, scale: 2
      t.integer :year_built
      t.decimal :estimated_roi_min, precision: 7, scale: 3
      t.decimal :estimated_roi_max, precision: 7, scale: 3
      t.integer :equity_generated_min_cents
      t.integer :equity_generated_max_cents
      t.boolean :financing_available, null: false, default: false
      t.boolean :quota_available, null: false, default: false
      t.jsonb :property_details, null: false, default: {}
    end

    add_index :investment_cards, :market_status
  end
end
