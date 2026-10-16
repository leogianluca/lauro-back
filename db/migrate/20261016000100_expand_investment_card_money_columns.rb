class ExpandInvestmentCardMoneyColumns < ActiveRecord::Migration[8.1]
  MONEY_COLUMNS = %i[
    price_cents investment_min_cents investment_max_cents down_payment_cents
    current_income_cents projected_income_cents noi_current_cents noi_projected_cents
    ebitda_annual_cents annual_profit_cents owner_salary_annual_cents
    equity_generated_min_cents equity_generated_max_cents
  ].freeze

  def up
    MONEY_COLUMNS.each do |column|
      change_column :investment_cards, column, :bigint
    end
  end

  def down
    MONEY_COLUMNS.each do |column|
      change_column :investment_cards, column, :integer
    end
  end
end
