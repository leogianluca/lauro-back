class SiteAnalyticsEvent < ApplicationRecord
  EVENT_TYPES = %w[page_view navigation_click].freeze
  DEVICE_TYPES = %w[desktop tablet mobile].freeze

  validates :event_type, inclusion: { in: EVENT_TYPES }
  validates :path, :session_id, :occurred_at, presence: true
  validates :target_path, presence: true, if: -> { event_type == "navigation_click" }
  validates :device_type, inclusion: { in: DEVICE_TYPES }, allow_nil: true
  validates :session_id, format: { with: /\A[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/ }
  validates :path, :target_path, length: { maximum: 255 }
  validates :referrer_host, :utm_source, :utm_medium, :utm_campaign, length: { maximum: 120 }
end
