class AddResidentialYieldIndicatorsToInvestmentCards < ActiveRecord::Migration[8.0]
  def change
    add_column :investment_cards, :gross_yield_percent, :decimal, precision: 7, scale: 3
    add_column :investment_cards, :hpi_10_year_percent, :decimal, precision: 7, scale: 3
  end
end
