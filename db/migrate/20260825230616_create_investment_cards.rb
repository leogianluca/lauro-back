class CreateInvestmentCards < ActiveRecord::Migration[8.1]
  def change
    create_table :investment_cards, id: :uuid do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :summary
      t.text :description
      t.string :category
      t.string :asset_type
      t.string :strategy
      t.string :city
      t.string :state
      t.string :country, null: false, default: "US"
      t.string :status, null: false, default: "draft"
      t.string :visibility, null: false, default: "public"
      t.integer :card_level, null: false, default: 1
      t.boolean :featured, null: false, default: false
      t.boolean :expert_curated, null: false, default: false
      t.integer :featured_position
      t.integer :price_cents
      t.string :price_currency, null: false, default: "USD"
      t.integer :investment_min_cents
      t.integer :investment_max_cents
      t.string :source_url
      t.string :external_reference
      t.jsonb :metadata, null: false, default: {}
      t.datetime :published_at
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :investment_cards, :slug, unique: true
    add_index :investment_cards, :status
    add_index :investment_cards, :visibility
    add_index :investment_cards, :category
    add_index :investment_cards, :asset_type
    add_index :investment_cards, :strategy
    add_index :investment_cards, :city
    add_index :investment_cards, :featured
    add_index :investment_cards, :expert_curated
    add_index :investment_cards, :featured_position
    add_index :investment_cards, :published_at
    add_index :investment_cards, :discarded_at
    add_index :investment_cards, :metadata, using: :gin
  end
end
