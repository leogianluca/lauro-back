module Api
  module V1
    class ContentPagesController < ApplicationController
      include PublicLocale

      def index
        pages = public_pages
        pagination, pages = paginate_collection(pages)
        localized_pages = pages.map { |page| localize_public_record(page, ContentPageBlueprint.render_as_hash(page)) }
        render_success(data: localized_pages, meta: pagination_meta(pagination, public_locale_meta(localized_pages)))
      end

      def show
        page = public_pages.find_by!(slug: params[:slug])
        render_success(data: localize_public_record(page, ContentPageBlueprint.render_as_hash(page, view: :detail)))
      end

      private

      def public_pages
        ContentPage.published_for_public
          .with_attached_images
          .with_attached_documents
          .with_attached_seo_image
      end
    end
  end
end
