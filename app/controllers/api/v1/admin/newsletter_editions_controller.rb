module Api
  module V1
    module Admin
      class NewsletterEditionsController < BaseController
        require "csv"
        def index
          editions = NewsletterEdition.kept.order(updated_at: :desc)
          editions = editions.where(status: params[:status]) if params[:status].present?
          if params[:q].present?
            query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s)}%"
            editions = editions.where("title ILIKE :query OR excerpt ILIKE :query", query:)
          end
          pagination, editions = paginate_collection(editions)
          render_success(data: NewsletterEditionBlueprint.render_as_hash(editions, view: :detail), meta: pagination_meta(pagination))
        end

        def show
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition
          render_success(data: NewsletterEditionBlueprint.render_as_hash(edition, view: :detail))
        end

        def send_campaign
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :dispatch?
          return render_error(code: "not_published", message: "The edition must be published before dispatch.", status: :unprocessable_content) unless edition.published?
          return render_error(code: "already_dispatched", message: "Esta campanha já foi enviada ou está em processamento.", status: :conflict) if edition.sending? || edition.sent?
          return render_error(code: "empty_audience", message: "A campanha precisa ter pelo menos um destinatário.", status: :unprocessable_content) if audience_empty?(edition)
          return render_error(code: "checklist_incomplete", message: "A checklist da campanha precisa estar completa antes do envio.", status: :unprocessable_content) unless review_checklist(edition).values.all?

          segment_id = edition.metadata["segment_id"].presence
          edition.with_lock do
            if edition.metadata["dispatch_queued_at"].present?
              return render_error(code: "already_dispatched", message: "Esta campanha já está enfileirada.", status: :conflict)
            end

            edition.update!(metadata: edition.metadata.merge("dispatch_queued_at" => Time.current.iso8601))
            DeliverNewsletterCampaignJob.perform_later(edition.id, segment_id)
          end
          render_success(data: { queued: true, edition_id: edition.id, segment_id: }, status: :accepted)
        end

        def create
          edition = NewsletterEdition.new(edition_params)
          authorize edition
          edition.save!
          NewsletterCampaigns::Compose.new(edition).call
          record_version(edition, "Criação")
          render_success(data: NewsletterEditionBlueprint.render_as_hash(edition, view: :detail), status: :created)
        end

        def update
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition
          edition.update!(edition_params)
          NewsletterCampaigns::Compose.new(edition).call
          record_version(edition, "Edição atualizada")
          audit!("newsletter_edition.updated", edition)
          render_success(data: NewsletterEditionBlueprint.render_as_hash(edition, view: :detail))
        end

        def destroy
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition
          edition.discard!
          audit!("newsletter_edition.archived", edition)
          render_success(data: nil)
        end

        def media
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :update?
          NewsletterContents::MediaAttacher.new(edition, images: params[:images], documents: params[:documents]).call
          edition.cover_image.attach(params[:cover_image]) if params[:cover_image].present?
          edition.seo_image.attach(params[:seo_image]) if params[:seo_image].present?
          render_success(data: NewsletterEditionBlueprint.render_as_hash(edition, view: :detail))
        end

        def remove_media
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :update?
          attachment = Attachments::Purge.new(edition, name: params[:name], attachment_id: params[:attachment_id], user: current_user).call
          render_success(data: { attachment_id: attachment.id, status: "queued" }, status: :accepted)
        end

        def publish
          transition(:publish)
        end

        def request_review
          transition_to(:in_review, :request_review)
        end

        def approve
          transition_to(:approved, :approve)
        end

        def reject
          transition_to(:draft, :reject)
        end

        def schedule
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :schedule?
          return render_error(code: "already_scheduled", message: "Esta campanha já está agendada ou foi processada.", status: :conflict) if edition.scheduled? || edition.sending? || edition.sent?
          at = Time.zone.parse(params.dig(:newsletter_edition, :scheduled_at).to_s)
          return render_error(code: "invalid_schedule", message: "Informe uma data futura.", status: :unprocessable_content) unless at && at.future?
          return render_error(code: "empty_audience", message: "A campanha precisa ter pelo menos um destinatário.", status: :unprocessable_content) if audience_scope(edition).none?
          freeze_audience!(edition)
          edition.schedule!(at)
          DeliverNewsletterCampaignJob.set(wait_until: at).perform_later(edition.id, edition.metadata["segment_id"].presence)
          render_success(data: NewsletterEditionBlueprint.render_as_hash(edition, view: :detail))
        end

        def send_test
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :dispatch?
          email = params[:email].to_s
          return render_error(code: "invalid_email", message: "Informe um e-mail válido.", status: :unprocessable_content) unless email.match?(URI::MailTo::EMAIL_REGEXP)
          NewsletterMailer.with(edition:, email:).test_email.deliver_later
          render_success(data: { queued: true, email: })
        end

        def audience
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :show?
          segment = params[:segment_id].present? ? NewsletterSegment.find(params[:segment_id]) : nil
          subscribers = segment ? NewsletterSegments::Matcher.new(segment).scope : NewsletterSubscriber.subscribed.order(created_at: :desc)
          render_success(data: { edition_id: edition.id, count: subscribers.count, subscribers: subscribers.limit(100).as_json(only: %i[id email]) })
        end

        def set_audience
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :update?
          segment_id = params.dig(:newsletter_edition, :segment_id).presence
          segment = segment_id ? NewsletterSegment.find(segment_id) : nil
          metadata = edition.metadata.to_h.merge("segment_id" => segment&.id).compact
          edition.update!(metadata:)
          edition.newsletter_edition_segments.delete_all
          edition.newsletter_edition_segments.create!(newsletter_segment: segment) if segment
          render_success(data: NewsletterEditionBlueprint.render_as_hash(edition, view: :detail))
        end

        def review
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :show?
          render_success(data: { edition: NewsletterEditionBlueprint.render_as_hash(edition, view: :detail), checklist: review_checklist(edition), comments: edition.newsletter_approval_comments.order(created_at: :asc) })
        end

        def preview
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :show?
          render_success(data: { edition_id: edition.id, html: preview_html(edition), desktop_html: preview_html(edition), mobile_html: preview_html(edition, mobile: true) })
        end

        def versions
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :show?
          render_success(data: edition.newsletter_edition_versions.order(version_number: :desc))
        end

        def restore_version
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :update?
          version = edition.newsletter_edition_versions.find(params[:version_id])
          snapshot = version.snapshot.to_h.stringify_keys.slice("title", "slug", "excerpt", "body", "status", "visibility", "published_at", "metadata")
          record_version(edition, "Antes da restauração da versão #{version.version_number}")
          edition.update!(snapshot)
          record_version(edition, "Restauração da versão #{version.version_number}")
          audit!("newsletter_edition.version_restored", edition)
          render_success(data: NewsletterEditionBlueprint.render_as_hash(edition, view: :detail))
        end

        def metrics
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :show?
          events = edition.newsletter_metric_events
          scoped_events = params[:from].present? ? events.where("occurred_at >= ?", Time.zone.parse(params[:from])) : events
          scoped_events = scoped_events.where("occurred_at <= ?", Time.zone.parse(params[:to]).end_of_day) if params[:to].present?
          scoped_counts = scoped_events.group(:event_type).count
          links = scoped_events.where(event_type: "clicked").group(:link_url).count
          deliveries = edition.newsletter_deliveries.sent
          deliveries = deliveries.where("sent_at >= ?", Time.zone.parse(params[:from])) if params[:from].present?
          deliveries = deliveries.where("sent_at <= ?", Time.zone.parse(params[:to]).end_of_day) if params[:to].present?
          delivered = deliveries.count
          render_success(data: { edition_id: edition.id, totals: scoped_counts, delivered:, open_rate: rate(scoped_counts["opened"], delivered), click_rate: rate(scoped_counts["clicked"], delivered), clicks_by_link: links })
        end

        def metrics_export
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :show?
          rows = edition.newsletter_metric_events.order(:occurred_at).pluck(:occurred_at, :event_type, :recipient_email, :link_url)
          csv = CSV.generate(headers: true) { |output| output << %w[occurred_at event_type recipient_email link_url]; rows.each { |row| output << row } }
          send_data csv, filename: "newsletter-#{edition.slug}-metrics.csv", type: "text/csv"
        end

        def comments
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :show?
          render_success(data: edition.newsletter_approval_comments.order(created_at: :asc))
        end

        def create_comment
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :show?
          comment = edition.newsletter_approval_comments.create!(user: current_user, body: params.require(:comment).fetch(:body))
          render_success(data: comment, status: :created)
        end

        def resolve_comment
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, :update?
          comment = edition.newsletter_approval_comments.find(params[:comment_id])
          comment.update!(status: params[:status].presence || "resolved")
          audit!("newsletter_comment.resolved", comment)
          render_success(data: comment)
        end

        def archive
          transition(:archive)
        end

        def hide
          transition(:hide)
        end

        def make_public
          transition(:show, :update?)
        end

        private

        def transition(action, policy_action = "#{action}?")
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, policy_action
          edition.public_send("#{action}!")
          audit!("newsletter_edition.#{action}", edition)
          render_success(data: NewsletterEditionBlueprint.render_as_hash(edition, view: :detail))
        end

        def transition_to(status, policy_action = :update)
          edition = NewsletterEdition.kept.find(params[:id])
          authorize edition, policy_action
          freeze_audience!(edition) if status.to_s == "approved"
          edition.update!(status:)
          render_success(data: NewsletterEditionBlueprint.render_as_hash(edition, view: :detail))
        end

        def review_checklist(edition)
          NewsletterCampaigns::ReviewChecklist.new(edition).call
        end

        def audience_scope(edition)
          segment_id = edition.metadata["segment_id"].presence
          segment_id ? NewsletterSegments::Matcher.new(NewsletterSegment.find(segment_id)).scope : NewsletterSubscriber.subscribed
        end

        def audience_empty?(edition)
          edition.metadata.key?("audience_snapshot") ? Array(edition.metadata["audience_snapshot"]).compact_blank.empty? : audience_scope(edition).none?
        end

        def preview_html(edition, mobile: false)
          title = ERB::Util.html_escape(edition.title)
          preheader = ERB::Util.html_escape(edition.metadata["preheader"].to_s)
          excerpt = ERB::Util.html_escape(edition.excerpt.to_s)
          body = NewsletterCampaigns::HtmlRenderer.new(edition).call
          width = mobile ? "width:375px;max-width:100%;margin:0 auto" : "max-width:680px;margin:24px auto"
          <<~HTML
            <!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1"><style>body{margin:0;background:#f4f5f7;color:#182230;font-family:Arial,sans-serif}main{#{width};background:#fff}header{padding:#{mobile ? 20 : 28}px;background:#0b1d3a;color:#fff}section{padding:#{mobile ? "20px" : "20px 28px"};border-bottom:1px solid #e5e7eb}footer{padding:20px 28px;color:#667085;font-size:12px;text-align:center}a{color:#0b57d0}</style></head><body><main><header><h1>#{title}</h1>#{preheader.present? ? "<p>#{preheader}</p>" : ""}</header>#{excerpt.present? ? "<section><p>#{excerpt}</p></section>" : ""}#{body}<footer>Florida Investments<br><a href="#unsubscribe">Descadastrar-se</a></footer></main></body></html>
          HTML
        end

        def rate(events, deliveries)
          return 0.0 if deliveries.to_i.zero?
          ((events.to_i.to_f / deliveries) * 100).round(2)
        end

        def record_version(edition, note)
          edition.newsletter_edition_versions.create!(created_by: current_user, version_number: edition.newsletter_edition_versions.maximum(:version_number).to_i + 1, snapshot: NewsletterEditionBlueprint.render_as_hash(edition, view: :detail), change_note: note)
        end

        def freeze_audience!(edition)
          segment_id = edition.metadata["segment_id"].presence
          subscribers = if segment_id
            segment = NewsletterSegment.find(segment_id)
            NewsletterSegments::Matcher.new(segment).scope
          else
            NewsletterSubscriber.subscribed.to_a
          end
          snapshot = subscribers.map(&:id)
          edition.update!(metadata: edition.metadata.merge("audience_snapshot" => snapshot, "audience_snapshot_count" => snapshot.size, "audience_frozen_at" => Time.current.iso8601))
        end

        def edition_params
          params.require(:newsletter_edition).permit(
            :title, :slug, :excerpt, :body, :status, :visibility, :published_at,
            :edition_date, :cta_label, :cta_url, :seo_title, :seo_description, metadata: {}
          )
        end
      end
    end
  end
end
