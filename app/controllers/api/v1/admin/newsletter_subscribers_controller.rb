module Api
  module V1
    module Admin
      class NewsletterSubscribersController < BaseController
        require "csv"
        def index
          authorize NewsletterSubscriber
          subscribers = NewsletterSubscriber.order(created_at: :desc)
          subscribers = subscribers.where(status: params[:status]) if params[:status].present?
          pagination, subscribers = paginate_collection(subscribers)
          render_success(data: NewsletterSubscriberBlueprint.render_as_hash(subscribers), meta: pagination_meta(pagination))
        end

        def update
          subscriber = NewsletterSubscriber.find(params[:id])
          authorize subscriber
          status = params.dig(:newsletter_subscriber, :status).presence || params[:status].presence
          status = status.to_s
          status == "unsubscribed" ? subscriber.unsubscribe! : subscriber.subscribe!
          render_success(data: NewsletterSubscriberBlueprint.render_as_hash(subscriber))
        end

        def destroy
          subscriber = NewsletterSubscriber.find(params[:id])
          authorize subscriber
          subscriber.anonymize!
          audit!("newsletter_subscriber.anonymized", subscriber)
          render_success(data: nil)
        end

        def export
          authorize NewsletterSubscriber, :export?
          rows = NewsletterSubscriber.order(:created_at).pluck(:email, :source, :status, :subscribed_at, :unsubscribed_at)
          csv = CSV.generate(headers: true) { |output| output << %w[email source status subscribed_at unsubscribed_at]; rows.each { |row| output << row } }
          send_data csv, filename: "newsletter-subscribers.csv", type: "text/csv"
        end
      end
    end
  end
end
