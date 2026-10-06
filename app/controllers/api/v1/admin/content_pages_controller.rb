module Api
  module V1
    module Admin
      class ContentPagesController < BaseController
        def index
          pages = ContentPage.kept.order(updated_at: :desc)
          pagination, pages = paginate_collection(pages)
          render_success(data: ContentPageBlueprint.render_as_hash(pages, view: :detail), meta: pagination_meta(pagination))
        end

        def show
          page = ContentPage.kept.find(params[:id])
          authorize page
          render_success(data: ContentPageBlueprint.render_as_hash(page, view: :detail))
        end

        def create
          page = ContentPage.new(page_params)
          authorize page
          page.save!
          render_success(data: ContentPageBlueprint.render_as_hash(page, view: :detail), status: :created)
        end

        def update
          page = ContentPage.kept.find(params[:id])
          authorize page
          page.update!(page_params)
          render_success(data: ContentPageBlueprint.render_as_hash(page, view: :detail))
        end

        def destroy
          page = ContentPage.kept.find(params[:id])
          authorize page
          page.discard!
          render_success(data: nil)
        end

        def media
          page = ContentPage.kept.find(params[:id])
          authorize page, :update?
          NewsletterContents::MediaAttacher.new(page, images: params[:images], documents: params[:documents]).call
          page.seo_image.attach(params[:seo_image]) if params[:seo_image].present?
          render_success(data: ContentPageBlueprint.render_as_hash(page, view: :detail))
        end

        def remove_media
          page = ContentPage.kept.find(params[:id])
          authorize page, :update?
          attachment = Attachments::Purge.new(page, name: params[:name], attachment_id: params[:attachment_id], user: current_user).call
          render_success(data: { attachment_id: attachment.id, status: "queued" }, status: :accepted)
        end

        def make_public
          page = ContentPage.kept.find(params[:id])
          authorize page, :make_public?
          page.show!
          render_success(data: ContentPageBlueprint.render_as_hash(page, view: :detail))
        end

        %w[publish archive hide].each do |action|
          define_method(action) do
            page = ContentPage.kept.find(params[:id])
            authorize page, "#{action}?"
            page.public_send("#{action}!")
            render_success(data: ContentPageBlueprint.render_as_hash(page, view: :detail))
          end
        end

        private

        def page_params
          params.require(:content_page).permit(
            :title, :slug, :page_type, :eyebrow, :excerpt, :body, :status,
            :visibility, :published_at, :template_key, :seo_title, :seo_description,
            metadata: {}, content_blocks: []
          )
        end
      end
    end
  end
end
