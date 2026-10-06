class DealSubmissionPolicy < ApplicationPolicy
  def index?
    admin? || editor? || viewer?
  end

  def show?
    admin? || editor? || viewer?
  end

  def update?
    admin? || editor?
  end

  def destroy?
    admin?
  end
end
