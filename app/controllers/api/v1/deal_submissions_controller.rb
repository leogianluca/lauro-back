module Api
  module V1
    class DealSubmissionsController < ApplicationController
      MAX_AMOUNT_CENTS = 2_147_483_647
      MAX_IMAGES = 10
      MAX_DOCUMENTS = 10
      AMOUNT_FIELDS = %w[price_cents investment_min_cents].freeze

      def create
        return render_error(code: "consent_required", message: "Consent is required to submit a deal.", status: :unprocessable_content) unless ActiveModel::Type::Boolean.new.cast(params[:consent])
        if (field = too_many_files_field)
          return render_error(
            code: "too_many_files",
            message: "A maximum of 10 images and 10 documents is allowed.",
            field:
          )
        end
        if (field = invalid_amount_field)
          return render_error(
            code: "invalid_amount",
            message: "Amount must be a non-negative integer in cents within the supported range.",
            field: "deal_submission.#{field}"
          )
        end

        submission = DealSubmission.new(submission_params)
        submission.consented_at = Time.current
        DealSubmission.transaction do
          submission.save!
          attach_files!(submission)
        end
        render_success(data: PublicDealSubmissionBlueprint.render_as_hash(submission), status: :created)
      end

      private

      def too_many_files_field
        return "images" if Array(params[:images]).compact.size > MAX_IMAGES
        return "documents" if Array(params[:documents]).compact.size > MAX_DOCUMENTS

        nil
      end

      def invalid_amount_field
        AMOUNT_FIELDS.find do |field|
          value = params.dig(:deal_submission, field)
          next false if value.nil? || value == ""

          !value.to_s.match?(/\A\d+\z/) || value.to_i > MAX_AMOUNT_CENTS
        end
      end

      def submission_params
        params.require(:deal_submission).permit(
          :submitter_name, :submitter_email, :company_name, :title, :category,
          :asset_type, :strategy, :address_line1, :city, :state, :region, :country, :zip_code,
          :price_cents, :investment_min_cents, :message, metadata: {}
        )
      end

      def attach_files!(submission)
        NewsletterContents::MediaAttacher.new(
          submission,
          images: params[:images],
          documents: params[:documents]
        ).call
      end
    end
  end
end
