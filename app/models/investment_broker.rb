class InvestmentBroker < ApplicationRecord
  has_many :investment_cards, dependent: :nullify

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end
