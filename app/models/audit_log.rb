class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :action, :auditable_type, :auditable_id, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def self.record!(user:, action:, record:, request: nil)
    create!(
      user:,
      action:,
      auditable_type: record.class.base_class.name,
      auditable_id: record.id,
      changeset: record.saved_changes.except("updated_at"),
      ip_address: request&.remote_ip,
      request_id: request&.request_id
    )
  end
end
