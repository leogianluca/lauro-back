class NewsletterSegment < ApplicationRecord
  CONDITION_FIELDS = %w[email city state language source interest price strategy consent].freeze
  CONDITION_OPERATORS = %w[equals not_equals contains not_contains greater_than greater_than_or_equal less_than less_than_or_equal in].freeze

  has_many :newsletter_edition_segments, dependent: :destroy
  has_many :newsletter_editions, through: :newsletter_edition_segments
  enum :status, { active: "active", archived: "archived" }, default: :active, validate: true
  enum :logic, { all_rules: "and", any_rule: "or" }, default: :all_rules, prefix: true, validate: true
  validates :name, presence: true
  validate :validate_conditions

  private

  def validate_conditions
    unless conditions.is_a?(Array)
      errors.add(:conditions, "must be an array")
      return
    end

    conditions.each_with_index do |condition, index|
      condition = condition.to_h.stringify_keys
      field = condition["field"].to_s
      operator = condition["operator"].presence || "equals"
      value = condition["value"]
      errors.add(:conditions, "condition #{index + 1} has an invalid field") unless CONDITION_FIELDS.include?(field)
      errors.add(:conditions, "condition #{index + 1} has an invalid operator") unless CONDITION_OPERATORS.include?(operator)
      errors.add(:conditions, "condition #{index + 1} requires a value") if value.nil? || (value.is_a?(String) && value.strip.empty?)
    end
  end
end
