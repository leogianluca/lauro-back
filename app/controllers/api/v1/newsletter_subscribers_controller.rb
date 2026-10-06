module Api
  module V1
    class NewsletterSubscribersController < ApplicationController
      def create
        return render_error(code: "consent_required", message: "Consent is required to subscribe.", status: :unprocessable_content) unless ActiveModel::Type::Boolean.new.cast(params[:consent])

        email = subscriber_params[:email].to_s.strip.downcase
        subscriber = NewsletterSubscriber.find_or_initialize_by(email: email)
        subscriber.assign_attributes(source: subscriber_params[:source], metadata: subscriber_params[:metadata] || {})
        subscriber.subscribe!
        render_success(
          data: {
            subscribed: true,
            unsubscribe_token: subscriber.signed_id(purpose: "newsletter_unsubscribe")
          },
          status: :created
        )
      end

      def destroy
        unsubscribe
      end

      def unsubscribe
        subscriber = NewsletterSubscriber.find_signed!(params[:id], purpose: "newsletter_unsubscribe")
        subscriber.unsubscribe!
        render_success(data: { subscribed: false })
      end

      private

      def subscriber_params
        params.require(:subscriber).permit(:email, :source, metadata: {})
      end
    end
  end
end
