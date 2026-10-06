module Api
  module V1
    module Admin
      class NewsletterContentsController < BaseController
        before_action :set_content, only: %i[show update destroy publish archive favorite unfavorite media remove_media preview]

        def index
          authorize NewsletterContent
          scope = NewsletterContent.available
          scope = scope.where(content_type: params[:type]) if params[:type].present?
          scope = scope.where(status: params[:status]) if params[:status].present?
          scope = scope.where("title ILIKE ?", "%#{params[:q]}%") if params[:q].present?
          scope = scope.favorites if params[:favorite].to_s == "true"
          scope = scope.recently_used if params[:used].to_s == "recent"
          pagination, contents = paginate_collection(scope)
          render_success(data: NewsletterContentBlueprint.render_as_hash(contents), meta: pagination_meta(pagination))
        end

        def show
          authorize @content
          render_success(data: NewsletterContentBlueprint.render_as_hash(@content))
        end

        def create
          content = NewsletterContent.new(content_params)
          authorize content
          content.save!
          audit!("newsletter_content.created", content)
          render_success(data: NewsletterContentBlueprint.render_as_hash(content), status: :created)
        end

        def update
          authorize @content
          @content.update!(content_params)
          audit!("newsletter_content.updated", @content)
          render_success(data: NewsletterContentBlueprint.render_as_hash(@content))
        end

        def destroy
          authorize @content
          @content.discard!
          audit!("newsletter_content.archived", @content)
          render_success(data: nil)
        end

        def publish
          authorize @content, :update?
          checklist = publication_checklist(@content)
          return render_error(code: "checklist_incomplete", message: "Complete the item checklist before publishing.", status: :unprocessable_content) unless checklist.values.all?

          @content.update!(status: :published, published_at: Time.current)
          audit!("newsletter_content.published", @content)
          render_success(data: NewsletterContentBlueprint.render_as_hash(@content))
        end

        def preview
          authorize @content, :show?
          checklist = publication_checklist(@content)
          preview = NewsletterCampaigns::ContentPreview.new(@content)
          render_success(data: { item: NewsletterContentBlueprint.render_as_hash(@content), checklist:, publishable: checklist.values.all?, html: preview.call, desktop_html: preview.call, mobile_html: preview.call(mobile: true) })
        end

        def archive
          authorize @content, :update?
          @content.update!(status: :archived)
          render_success(data: NewsletterContentBlueprint.render_as_hash(@content))
        end

        def favorite
          authorize @content, :update?
          @content.update!(favorite: true)
          render_success(data: NewsletterContentBlueprint.render_as_hash(@content))
        end

        def unfavorite
          authorize @content, :update?
          @content.update!(favorite: false)
          render_success(data: NewsletterContentBlueprint.render_as_hash(@content))
        end

        def media
          authorize @content, :update?
          NewsletterContents::MediaAttacher.new(
            @content,
            images: params[:images],
            documents: params[:documents]
          ).call
          render_success(data: NewsletterContentBlueprint.render_as_hash(@content))
        end

        def remove_media
          authorize @content, :update?
          attachment = Attachments::Purge.new(@content, name: params[:name], attachment_id: params[:attachment_id], user: current_user).call
          render_success(data: { attachment_id: attachment.id, status: "queued" }, status: :accepted)
        end

        private

        def set_content
          @content = NewsletterContent.kept.find(params[:id])
        end

        def content_params
          params.require(:newsletter_content).permit(:title, :slug, :content_type, :category, :status, :favorite, :subtitle, :description, :cta_label, :cta_url, :cta_target, :tracking_key, :alt_text, :event_date, :event_time, :event_timezone, :event_location, :registration_url, :investment_card_id, tags: [], metadata: {})
        end

        def publication_checklist(content)
          {
            title: content.title.present?,
            description: content.description.present?,
            alt_text: content.images.none? || content.alt_text.present?,
            links: [ content.cta_url, content.registration_url ].compact_blank.all? { |url| url.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https])) },
            event_details: !content.event? || [ content.event_date, content.event_time, content.event_timezone, content.event_location ].all?(&:present?)
          }
        end
      end
    end
  end
end
