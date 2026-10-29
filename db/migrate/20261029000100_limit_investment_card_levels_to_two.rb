class LimitInvestmentCardLevelsToTwo < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE investment_cards SET card_level = 2 WHERE card_level = 3"
    remove_check_constraint :investment_cards, name: "investment_cards_card_level_range", if_exists: true
    remove_check_constraint :investment_cards, name: "investment_cards_card_level_valid", if_exists: true
    add_check_constraint :investment_cards, "card_level BETWEEN 1 AND 2", name: "investment_cards_card_level_range"
  end

  def down
    remove_check_constraint :investment_cards, name: "investment_cards_card_level_range", if_exists: true
    add_check_constraint :investment_cards, "card_level BETWEEN 1 AND 3", name: "investment_cards_card_level_range"
    add_check_constraint :investment_cards, "card_level BETWEEN 1 AND 3", name: "investment_cards_card_level_valid"
  end
end
