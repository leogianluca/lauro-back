module Api
  module V1
    module Admin
      class DealSubmissionsController < BaseController
        def index
          submissions = DealSubmission.kept.recent
          submissions = submissions.where(status: params[:status]) if params[:status].present?
          pagination, submissions = paginate_collection(submissions)
          render_success(data: DealSubmissionBlueprint.render_as_hash(submissions), meta: pagination_meta(pagination))
        end

        def show
          submission = DealSubmission.kept.find(params[:id])
          authorize submission
          render_success(data: DealSubmissionBlueprint.render_as_hash(submission, view: :detail))
        end

        def attachment
          submission = DealSubmission.kept.find(params[:id])
          authorize submission, :show?
          attachment = (submission.images.attachments + submission.documents.attachments).find do |item|
            item.id.to_s == params[:attachment_id]
          end
          raise ActiveRecord::RecordNotFound unless attachment

          response.headers["Content-Type"] = attachment.blob.content_type
          response.headers["Content-Disposition"] = ActionDispatch::Http::ContentDisposition.format(
            disposition: "attachment", filename: attachment.filename.to_s
          )
          response.headers["Cache-Control"] = "private, no-store"
          self.response_body = Enumerator.new do |stream|
            attachment.blob.download { |chunk| stream << chunk }
          end
        end

        def update
          submission = DealSubmission.kept.find(params[:id])
          authorize submission
          submission.update!(status_params)
          render_success(data: DealSubmissionBlueprint.render_as_hash(submission))
        end

        def destroy
          submission = DealSubmission.kept.find(params[:id])
          authorize submission
          submission.discard!
          render_success(data: nil)
        end

        def convert
          submission = DealSubmission.kept.find(params[:id])
          authorize submission, :update?
          card = DealSubmissions::ConvertToInvestmentCard.new(submission, user: current_user).call
          audit!("deal_submission.converted", submission)
          render_success(data: InvestmentCardBlueprint.render_as_hash(card, view: :detail), status: :created)
        end

        private

        def status_params
          params.require(:deal_submission).permit(:status, :internal_notes)
        end
      end
    end
  end
end
