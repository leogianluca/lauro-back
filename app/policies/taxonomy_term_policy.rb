class TaxonomyTermPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.admin? || user&.editor? || user&.viewer?

      scope.none
    end
  end
end
