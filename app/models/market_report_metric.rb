class MarketReportMetric < ApplicationRecord
  belongs_to :market_report
  belongs_to :taxonomy_term, optional: true

  acts_as_list scope: :market_report

  validates :label, :value, presence: true
  validate :published_report_has_source

  private

  def published_report_has_source
    return unless market_report&.published? && market_report.source_name.blank?

    errors.add(:base, "a published report metric requires a report source")
  end
end
