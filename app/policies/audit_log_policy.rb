class AuditLogPolicy < ApplicationPolicy
  def index?
    user&.admin?
  end

  def show?
    index?
  end
end
