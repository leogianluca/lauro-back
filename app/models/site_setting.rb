class SiteSetting < ApplicationRecord
  validates :key, :category, presence: true
  validates :key, uniqueness: true

  scope :publicly_visible, -> { where(public: true) }
end
