class AddConsentToDealSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :deal_submissions, :consented_at, :datetime
  end
end
