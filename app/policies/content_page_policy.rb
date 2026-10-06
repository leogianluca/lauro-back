class ContentPagePolicy < ApplicationPolicy
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
end
