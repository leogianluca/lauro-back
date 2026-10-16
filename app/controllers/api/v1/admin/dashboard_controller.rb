module Api
  module V1
    module Admin
      class DashboardController < BaseController
        def show
          return render_error(code: "forbidden", message: "Admin or editor access is required.", status: :forbidden) unless current_user.admin? || current_user.editor?

          data = {
            investment_cards: {
              active: InvestmentCard.kept.count,
              published: InvestmentCard.kept.published.publicly_visible.count,
              drafts: InvestmentCard.kept.draft.count,
              featured: InvestmentCard.kept.featured.count
            },
            content: {
              published_pages: ContentPage.kept.published.count,
              newsletter_editions: NewsletterEdition.kept.published.count,
              market_reports: MarketReport.kept.published.count
            },
            leads: {
              total: Lead.kept.count,
              new: Lead.kept.new_lead.count,
              qualified: Lead.kept.qualified.count
            },
            deal_submissions: {
              total: DealSubmission.kept.count,
              new: DealSubmission.kept.new_submission.count,
              reviewing: DealSubmission.kept.reviewing.count
            },
            newsletter: {
              editions: {
                drafts: NewsletterEdition.kept.draft.count,
                scheduled: NewsletterEdition.kept.scheduled.count,
                sent: NewsletterEdition.kept.sent.count
              },
              subscribed: NewsletterSubscriber.subscribed.count,
              unsubscribed: NewsletterSubscriber.unsubscribed.count,
              last_30_days: newsletter_metrics
            },
            workflow: {
              media_imports_processing: MediaImportBatch.processing.count,
              failed_media_items: MediaImportItem.failed.count,
              leads_waiting: Lead.kept.new_lead.count,
              leads_over_24h: Lead.kept.new_lead.where("created_at < ?", 24.hours.ago).count,
              submissions_waiting: DealSubmission.kept.new_submission.count,
              submissions_reviewing: DealSubmission.kept.reviewing.count,
              newsletters_awaiting_approval: NewsletterEdition.kept.awaiting_approval.count,
              newsletters_with_error: NewsletterEdition.kept.error.count
            },
            inventory: {
              published_by_category: InvestmentCard.kept.published.publicly_visible.group(:category).count,
              recent_cards: InvestmentCard.kept.order(updated_at: :desc).limit(5).pluck(:id, :title, :category, :status, :updated_at).map do |id, title, category, status, updated_at|
                { id:, title:, category:, status:, updated_at: }
              end
            }
          }
          unless current_user.admin?
            data.delete(:leads)
            data[:workflow].delete(:leads_waiting)
            data[:workflow].delete(:leads_over_24h)
          end
          data[:traffic] = traffic_snapshot if current_user.admin?
          render_success(data: data)
        end

        private

        def newsletter_metrics
          since = 30.days.ago
          deliveries = NewsletterDelivery.sent.where("sent_at >= ?", since)
          events = NewsletterMetricEvent.where("occurred_at >= ?", since)
          delivered = deliveries.count
          opened = events.where(event_type: :opened).distinct.count(:newsletter_delivery_id)
          clicked = events.where(event_type: :clicked).distinct.count(:newsletter_delivery_id)

          {
            delivered: delivered,
            opened: opened,
            clicked: clicked,
            open_rate: percentage(opened, delivered),
            click_rate: percentage(clicked, delivered)
          }
        end

        def traffic_snapshot
          since = 30.days.ago
          views = SiteAnalyticsEvent.where(event_type: "page_view").where("occurred_at >= ?", since)
          {
            page_views: views.count,
            sessions: views.distinct.count(:session_id),
            top_pages: views.group(:path).order(Arel.sql("COUNT(*) DESC")).limit(4).count.map do |path, count|
              { path:, count: }
            end
          }
        end

        def percentage(numerator, denominator)
          return 0.0 if denominator.zero?

          (numerator.to_f / denominator * 100).round(2)
        end
      end
    end
  end
end
