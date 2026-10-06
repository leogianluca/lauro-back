class InvestmentCardMetric < ApplicationRecord
  belongs_to :investment_card
  belongs_to :taxonomy_term, optional: true

  acts_as_list scope: :investment_card

  validates :label, :value, presence: true
end
