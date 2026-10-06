class AllowSpamComplaintsInNewsletterMetrics < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :newsletter_metric_events, name: "newsletter_metric_events_type_allowed"
    add_check_constraint :newsletter_metric_events, "event_type IN ('delivered', 'opened', 'clicked', 'bounced', 'unsubscribed', 'spam_complaint')", name: "newsletter_metric_events_type_allowed"
  end
end
