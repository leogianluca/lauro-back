class InvestmentLocation < ApplicationRecord
  has_many :investment_cards, dependent: :nullify

  validates :name, presence: true
  validates :country, presence: true
end
