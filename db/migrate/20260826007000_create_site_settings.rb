class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings, id: :uuid do |t|
      t.string :key, null: false
      t.jsonb :value, null: false, default: {}
      t.string :category, null: false, default: "general"
      t.boolean :public, null: false, default: false
      t.text :description
      t.timestamps
    end

    add_index :site_settings, :key, unique: true
    add_index :site_settings, :category
    add_index :site_settings, :public
  end
end
