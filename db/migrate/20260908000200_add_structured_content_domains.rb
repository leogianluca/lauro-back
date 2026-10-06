class AddStructuredContentDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :taxonomy_terms, id: :uuid do |t|
      t.string :kind, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.references :parent, type: :uuid, foreign_key: { to_table: :taxonomy_terms }
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :taxonomy_terms, [ :kind, :slug ], unique: true
    add_index :taxonomy_terms, [ :kind, :active, :position ], name: "idx_taxonomy_terms_listing"

    create_table :investment_card_metrics, id: :uuid do |t|
      t.references :investment_card, type: :uuid, null: false, foreign_key: true
      t.references :taxonomy_term, type: :uuid, foreign_key: true
      t.string :label, null: false
      t.string :value, null: false
      t.string :unit
      t.integer :position, null: false, default: 0
      t.boolean :featured, null: false, default: false
      t.text :description
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :investment_card_metrics, [ :investment_card_id, :position ], name: "idx_card_metrics_position"

    create_table :market_report_metrics, id: :uuid do |t|
      t.references :market_report, type: :uuid, null: false, foreign_key: true
      t.references :taxonomy_term, type: :uuid, foreign_key: true
      t.string :label, null: false
      t.string :value, null: false
      t.string :unit
      t.string :variation
      t.integer :position, null: false, default: 0
      t.boolean :featured, null: false, default: false
      t.text :description
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :market_report_metrics, [ :market_report_id, :position ], name: "idx_report_metrics_position"

    create_table :investment_card_media, id: :uuid do |t|
      t.references :investment_card, type: :uuid, null: false, foreign_key: true
      t.string :kind, null: false, default: "gallery"
      t.string :alt_text
      t.string :caption
      t.integer :position, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :investment_card_media, [ :investment_card_id, :position ], name: "idx_card_media_position"

    change_table :investment_cards do |t|
      t.references :category_taxonomy, type: :uuid, foreign_key: { to_table: :taxonomy_terms }
      t.references :asset_type_taxonomy, type: :uuid, foreign_key: { to_table: :taxonomy_terms }
      t.references :strategy_taxonomy, type: :uuid, foreign_key: { to_table: :taxonomy_terms }
      t.references :market_taxonomy, type: :uuid, foreign_key: { to_table: :taxonomy_terms }
      t.text :assumptions
      t.text :market_context
      t.text :investment_profile
      t.text :return_strategy
      t.text :expert_curated_reason
      t.text :expert_curated_analysis
      t.string :seo_title
      t.text :seo_description
    end

    change_table :market_reports do |t|
      t.string :market_name
      t.string :region
      t.string :source_name
      t.string :source_url
      t.string :embed_url
      t.string :seo_title
      t.text :seo_description
    end

    change_table :newsletter_editions do |t|
      t.date :edition_date
      t.string :cta_label
      t.string :cta_url
      t.string :seo_title
      t.text :seo_description
    end

    change_table :content_pages do |t|
      t.string :template_key
      t.jsonb :content_blocks, null: false, default: []
      t.string :seo_title
      t.text :seo_description
    end

    add_reference :leads, :investment_card, type: :uuid, foreign_key: true

    change_table :deal_submissions do |t|
      t.string :title
      t.string :address_line1
      t.string :city
      t.string :state
      t.string :region
      t.string :country, null: false, default: "US"
      t.string :zip_code
      t.string :strategy
      t.integer :price_cents
      t.integer :investment_min_cents
      t.text :internal_notes
      t.references :converted_investment_card, type: :uuid, foreign_key: { to_table: :investment_cards }
    end
  end
end
