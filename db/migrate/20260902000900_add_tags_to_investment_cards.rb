class AddTagsToInvestmentCards < ActiveRecord::Migration[8.1]
  def change
    add_column :investment_cards, :tags, :jsonb, null: false, default: []
    add_index :investment_cards, :tags, using: :gin
  end
end
