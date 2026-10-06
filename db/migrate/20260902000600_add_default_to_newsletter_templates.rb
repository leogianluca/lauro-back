class AddDefaultToNewsletterTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :newsletter_templates, :default_template, :boolean, null: false, default: false
    add_index :newsletter_templates, :default_template, unique: true, where: "default_template = true AND discarded_at IS NULL", name: "idx_newsletter_templates_one_default"
  end
end
