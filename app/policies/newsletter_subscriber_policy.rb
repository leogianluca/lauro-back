class NewsletterSubscriberPolicy < ApplicationPolicy
  def index?
    admin? || editor? || viewer?
  end

  def update?
    admin? || editor?
  end

  def destroy?
    admin?
  end

  def export?
    admin?
  end
end
