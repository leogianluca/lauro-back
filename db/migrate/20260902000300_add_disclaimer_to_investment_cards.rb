class AddDisclaimerToInvestmentCards < ActiveRecord::Migration[8.1]
  def change
    add_column :investment_cards, :disclaimer, :text
  end
end
