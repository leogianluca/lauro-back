class AddNewsletterEditionToMediaImportBatches < ActiveRecord::Migration[8.1]
  def change
    change_column_null :media_import_batches, :investment_card_id, true
    add_reference :media_import_batches, :newsletter_edition, type: :uuid, foreign_key: true
  end
end
