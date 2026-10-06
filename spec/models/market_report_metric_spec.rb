require "rails_helper"

RSpec.describe MarketReportMetric, type: :model do
  it "rejects a metric added to a published report without a cited source" do
    report = create(:market_report, :published, metrics: {}, source_name: nil)

    metric = report.market_report_metrics.build(label: "Vacancy rate", value: "6.1%")

    expect(metric).not_to be_valid
    expect(metric.errors[:base]).to include("a published report metric requires a report source")
  end
end
