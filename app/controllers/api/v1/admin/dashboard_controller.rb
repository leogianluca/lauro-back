module Api
  module V1
    module Admin
      class DashboardController < BaseController
        def show
          render_success(data: {
            investment_cards: {
              active: InvestmentCard.kept.count,
              published: InvestmentCard.kept.published.count,
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
              failed_media_items: MediaImportItem.failed.count
            }
          })
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

        def percentage(numerator, denominator)
          return 0.0 if denominator.zero?

          (numerator.to_f / denominator * 100).round(2)
        end
      end
    end
  end
end
