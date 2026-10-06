class InvestmentCardPolicy < ApplicationPolicy
  def publish?
    admin? || editor?
  end

  def archive?
    admin? || editor?
  end

  def hide?
    admin? || editor?
  end

  def make_public?
    admin? || editor?
  end

  def feature?
    admin? || editor?
  end

  def unfeature?
    admin? || editor?
  end

  def mark_expert_curated?
    admin? || editor?
  end

  def unmark_expert_curated?
    admin? || editor?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.admin? || user&.editor? || user&.viewer?

      scope.published.kept
    end
  end
end
