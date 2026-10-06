class AddRegionToInvestmentCards < ActiveRecord::Migration[8.1]
  def change
    add_column :investment_cards, :region, :string
    add_index :investment_cards, :region
  end
end
