class NewsletterEditionPolicy < ApplicationPolicy
  def publish?
    admin? || editor?
  end

  def archive?
    admin? || editor?
  end

  def hide?
    admin? || editor?
  end

  def dispatch?
    admin? || editor?
  end

  def request_review?
    admin? || editor?
  end

  def approve?
    admin?
  end

  def reject?
    admin?
  end

  def schedule?
    admin?
  end
end
