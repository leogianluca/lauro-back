module Api
  module V1
    class NewsletterEditionsController < ApplicationController
      include PublicLocale

      def index
        editions = public_editions
        pagination, editions = paginate_collection(editions)
        localized_editions = editions.map { |edition| localize_public_record(edition, NewsletterEditionBlueprint.render_as_hash(edition)) }
        render_success(data: localized_editions, meta: pagination_meta(pagination, public_locale_meta(localized_editions)))
      end

      def show
        edition = public_editions.find_by!(slug: params[:slug])
        render_success(data: localize_public_record(edition, NewsletterEditionBlueprint.render_as_hash(edition, view: :detail)))
      end

      private

      def public_editions
        NewsletterEdition.published_for_public
          .with_attached_images
          .with_attached_documents
          .with_attached_cover_image
          .with_attached_seo_image
      end
    end
  end
end
