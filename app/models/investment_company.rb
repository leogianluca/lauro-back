class InvestmentCompany < ApplicationRecord
  has_many :investment_cards, dependent: :nullify

  validates :name, presence: true
end
