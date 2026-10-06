class AddSegmentLogic < ActiveRecord::Migration[8.1]
  def change
    add_column :newsletter_segments, :logic, :string, null: false, default: "and"
    add_index :newsletter_segments, :logic
  end
end
