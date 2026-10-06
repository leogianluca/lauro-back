module Api
  module V1
    module Admin
      class NewsletterTemplatesController < BaseController
        before_action :set_template, only: %i[show update destroy activate make_default duplicate preview versions restore_version]

        def index
          authorize NewsletterTemplate
          templates = NewsletterTemplate.available
          templates = templates.where(status: params[:status]) if params[:status].present?
          if params[:q].present?
            query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s)}%"
            templates = templates.where("name ILIKE :query", query:)
          end
          pagination, templates = paginate_collection(templates.order(updated_at: :desc))
          render_success(data: templates, meta: pagination_meta(pagination))
        end

        def show
          authorize @template
          render_success(data: @template)
        end

        def create
          template = NewsletterTemplate.new(template_params)
          authorize template
          template.save!
          audit!("newsletter_template.created", template)
          render_success(data: template, status: :created)
        end

        def update
          authorize @template
          record_version(@template, "Antes da atualização")
          @template.update!(template_params)
          audit!("newsletter_template.updated", @template)
          render_success(data: @template)
        end

        def destroy
          authorize @template
          record_version(@template, "Antes do arquivamento")
          @template.discard!
          audit!("newsletter_template.archived", @template)
          render_success(data: nil)
        end

        def activate
          authorize @template, :update?
          @template.update!(status: :active)
          audit!("newsletter_template.activated", @template)
          render_success(data: @template)
        end

        def make_default
          authorize @template, :update?
          @template.make_default!
          audit!("newsletter_template.default_set", @template)
          render_success(data: @template)
        end

        def duplicate
          authorize @template, :create?
          copy = @template.dup
          copy.name = "#{@template.name} (cópia)"
          copy.status = :draft
          copy.save!
          render_success(data: copy, status: :created)
        end

        def preview
          authorize @template, :show?
          preview = NewsletterCampaigns::TemplatePreview.new(@template)
          render_success(data: { template_id: @template.id, html: preview.call, desktop_html: preview.call, mobile_html: preview.call(mobile: true) })
        end

        def versions
          authorize @template, :show?
          render_success(data: @template.newsletter_template_versions.order(version_number: :desc))
        end

        def restore_version
          authorize @template, :update?
          version = @template.newsletter_template_versions.find(params[:version_id])
          record_version(@template, "Antes da restauração da versão #{version.version_number}")
          snapshot = version.snapshot.to_h.stringify_keys.slice("name", "status", "favorite", "default_template", "blocks", "branding")
          @template.update!(snapshot)
          record_version(@template, "Restauração da versão #{version.version_number}")
          audit!("newsletter_template.version_restored", @template)
          render_success(data: @template)
        end

        private

        def set_template
          @template = NewsletterTemplate.kept.find(params[:id])
        end

        def template_params
          params.require(:newsletter_template).permit(
            :name, :status, :favorite, :default_template,
            blocks: %i[id type title content image_url alt_text button_label button_url],
            branding: %i[primary_color logo_url footer_text header_text signature_text contact_text social_links]
          )
        end

        def record_version(template, note)
          template.newsletter_template_versions.create!(
            created_by: current_user,
            version_number: template.newsletter_template_versions.maximum(:version_number).to_i + 1,
            snapshot: template.attributes.slice("name", "status", "favorite", "default_template", "blocks", "branding"),
            change_note: note
          )
        end
      end
    end
  end
end
