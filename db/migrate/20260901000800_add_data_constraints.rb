class AddDataConstraints < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :investment_cards, "card_level BETWEEN 1 AND 3", name: "investment_cards_card_level_range"
    add_check_constraint :investment_cards, "price_cents IS NULL OR price_cents >= 0", name: "investment_cards_price_nonnegative"
    add_check_constraint :investment_cards, "investment_min_cents IS NULL OR investment_min_cents >= 0", name: "investment_cards_minimum_nonnegative"
    add_check_constraint :investment_cards, "investment_max_cents IS NULL OR investment_max_cents >= 0", name: "investment_cards_maximum_nonnegative"
    add_check_constraint :newsletter_contents, "content_type IN ('property', 'article', 'event', 'banner', 'cta', 'testimonial')", name: "newsletter_contents_type_allowed"
    add_check_constraint :newsletter_metric_events, "event_type IN ('delivered', 'opened', 'clicked', 'bounced', 'unsubscribed')", name: "newsletter_metric_events_type_allowed"
  end
end
