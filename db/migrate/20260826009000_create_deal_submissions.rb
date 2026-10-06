class CreateDealSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :deal_submissions, id: :uuid do |t|
      t.string :submitter_name, null: false
      t.string :submitter_email, null: false
      t.string :company_name
      t.string :category
      t.string :asset_type
      t.string :status, null: false, default: "new"
      t.text :message
      t.jsonb :metadata, null: false, default: {}
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :deal_submissions, :submitter_email
    add_index :deal_submissions, :status
    add_index :deal_submissions, :category
    add_index :deal_submissions, :discarded_at
  end
end
