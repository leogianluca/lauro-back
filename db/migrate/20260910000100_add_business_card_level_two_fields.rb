class AddBusinessCardLevelTwoFields < ActiveRecord::Migration[8.1]
  def change
    change_table :investment_cards do |t|
      t.integer :annual_profit_cents
      t.integer :owner_salary_annual_cents
      t.decimal :owner_time_in_business_years, precision: 6, scale: 2
      t.string :owner_involvement
      t.boolean :franchise, null: false, default: false
      t.string :sale_reason
      t.string :visa_eligibility
      t.jsonb :business_details, null: false, default: {}
    end

    add_index :investment_cards, :visa_eligibility
  end
end
