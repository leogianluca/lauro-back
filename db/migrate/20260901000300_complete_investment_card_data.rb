class CompleteInvestmentCardData < ActiveRecord::Migration[8.1]
  def change
    change_table :investment_cards do |t|
      t.string :address_line1
      t.string :address_line2
      t.string :zip_code
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.integer :current_income_cents
      t.integer :projected_income_cents
      t.integer :noi_current_cents
      t.integer :noi_projected_cents
      t.decimal :cap_rate_current, precision: 6, scale: 3
      t.decimal :cap_rate_projected, precision: 6, scale: 3
      t.decimal :cash_on_cash, precision: 6, scale: 3
      t.decimal :occupancy_rate, precision: 6, scale: 3
      t.integer :estimated_months
      t.string :sector
      t.integer :ebitda_annual_cents
      t.decimal :ebitda_margin, precision: 6, scale: 3
      t.string :operating_model
      t.decimal :investor_participation, precision: 6, scale: 3
      t.text :investment_thesis
      t.jsonb :highlights, null: false, default: []
      t.jsonb :risks, null: false, default: []
      t.jsonb :due_diligence, null: false, default: {}
      t.jsonb :financing, null: false, default: {}
      t.string :alt_text
      t.string :source_name
      t.datetime :verified_at
      t.uuid :curated_by_id
    end

    add_index :investment_cards, :zip_code
    add_index :investment_cards, :sector
    add_index :investment_cards, :verified_at
    add_foreign_key :investment_cards, :users, column: :curated_by_id
  end
end
