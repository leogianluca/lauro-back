class CreateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :investment_card, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end

    add_index :favorites, [ :user_id, :investment_card_id ], unique: true
  end
end
