class NewsletterSubscriberBlueprint < Blueprinter::Base
  identifier :id

  fields :email, :source, :status, :subscribed_at, :unsubscribed_at, :created_at, :updated_at
end
