class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  ROLES = {
    admin: "admin",
    editor: "editor",
    viewer: "viewer"
  }.freeze

  ROLE_PERMISSIONS = {
    "admin" => %w[
      users:manage
      settings:manage
      investment_cards:manage
      content:manage
      media:manage
      leads:manage
      newsletter:manage
      segments:manage
      templates:manage
      reports:manage
    ],
    "editor" => %w[
      investment_cards:manage
      content:manage
      media:manage
      leads:read
      newsletter:manage
      segments:manage
      templates:manage
      reports:manage
    ],
    "viewer" => %w[
      investment_cards:read
      content:read
      media:read
      leads:read
      newsletter:read
      segments:read
      templates:read
      reports:read
    ]
  }.freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  has_many :favorites, dependent: :destroy
  has_many :audit_logs, dependent: :nullify
  has_many :favorite_investment_cards, through: :favorites, source: :investment_card

  enum :role, ROLES, default: :viewer, validate: true

  validates :jti, presence: true, uniqueness: true

  before_validation :ensure_jti

  def permissions
    ROLE_PERMISSIONS.fetch(role)
  end

  private

  def ensure_jti
    self.jti ||= SecureRandom.uuid
  end
end
