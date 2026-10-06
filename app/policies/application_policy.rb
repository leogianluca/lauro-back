# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    admin? || editor? || viewer?
  end

  def show?
    admin? || editor? || viewer?
  end

  def create?
    admin? || editor?
  end

  def new?
    create?
  end

  def update?
    admin? || editor?
  end

  def edit?
    update?
  end

  def destroy?
    admin?
  end

  private

  def admin?
    user&.admin?
  end

  def editor?
    user&.editor?
  end

  def viewer?
    user&.viewer?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
