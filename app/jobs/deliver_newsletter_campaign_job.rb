class DeliverNewsletterCampaignJob < ApplicationJob
  queue_as :mailers

  def perform(edition_id, segment_id = nil)
    edition = NewsletterEdition.kept.where(status: %w[published scheduled]).find(edition_id)
    edition.update!(status: :sending)
    snapshot = Array(edition.metadata["audience_snapshot"]).compact_blank
    subscribers = if edition.metadata.key?("audience_snapshot")
      NewsletterSubscriber.subscribed.where(id: snapshot)
    elsif segment_id
      NewsletterSegments::Matcher.new(NewsletterSegment.find(segment_id)).scope
    end
    result = NewsletterCampaigns::Deliver.new(edition, subscribers:).call
    edition.update!(status: result[:failed].positive? ? :error : :sent, metadata: edition.metadata.merge("delivery_result" => result, "delivered_at" => Time.current.iso8601))
  end
end
