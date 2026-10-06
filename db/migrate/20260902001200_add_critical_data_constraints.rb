class AddCriticalDataConstraints < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :investment_cards, "card_level BETWEEN 1 AND 3", name: "investment_cards_card_level_valid"
    add_check_constraint :investment_cards, "price_cents IS NULL OR price_cents >= 0", name: "investment_cards_price_valid"
    add_check_constraint :investment_cards, "jsonb_typeof(tags) = 'array'", name: "investment_cards_tags_array"
    add_check_constraint :investment_cards, "jsonb_typeof(highlights) = 'array'", name: "investment_cards_highlights_array"
    add_check_constraint :investment_cards, "jsonb_typeof(risks) = 'array'", name: "investment_cards_risks_array"
    add_check_constraint :investment_cards, "jsonb_typeof(due_diligence) = 'object'", name: "investment_cards_due_diligence_object"
    add_check_constraint :investment_cards, "jsonb_typeof(financing) = 'object'", name: "investment_cards_financing_object"

    add_check_constraint :newsletter_deliveries, "attempts BETWEEN 0 AND 3", name: "newsletter_deliveries_attempts_valid"
    add_check_constraint :newsletter_contents, "cta_target IN ('_self', '_blank')", name: "newsletter_contents_cta_target_valid"
  end
end
