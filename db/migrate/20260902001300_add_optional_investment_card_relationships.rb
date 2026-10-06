class AddOptionalInvestmentCardRelationships < ActiveRecord::Migration[8.1]
  def change
    create_table :investment_brokers, id: :uuid do |t|
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :company_name
      t.timestamps
    end

    create_table :investment_companies, id: :uuid do |t|
      t.string :name, null: false
      t.string :sector
      t.string :website
      t.timestamps
    end

    create_table :investment_locations, id: :uuid do |t|
      t.string :name, null: false
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :zip_code
      t.string :country, null: false, default: "US"
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.timestamps
    end

    change_table :investment_cards do |t|
      t.references :investment_broker, type: :uuid, foreign_key: true
      t.references :investment_company, type: :uuid, foreign_key: true
      t.references :investment_location, type: :uuid, foreign_key: true
    end
  end
end
