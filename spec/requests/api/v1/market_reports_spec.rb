require "rails_helper"

RSpec.describe "Market reports", type: :request do
  it "returns only public published reports" do
    report = create(:market_report, :published, title: "May 2026 Report")
    create(:market_report, title: "Draft")
    create(:market_report, :published, visibility: "private", title: "Private")

    get "/api/v1/market_reports"

    expect(response).to have_http_status(:ok)
    expect(json_response["data"].map { |item| item["id"] }).to eq([ report.id ])
  end

  it "returns the full report by slug" do
    report = create(:market_report, :published, slug: "may-2026")

    get "/api/v1/market_reports/may-2026"

    expect(response).to have_http_status(:ok)
    expect(json_response.dig("data", "id")).to eq(report.id)
    expect(json_response.dig("data", "body")).to eq("Detailed report content.")
  end

  it "returns the standard not-found envelope for a missing public report" do
    get "/api/v1/market_reports/missing-report"

    expect(response).to have_http_status(:not_found)
    expect(json_response.dig("errors", 0, "code")).to eq("not_found")
    expect(json_response["data"]).to be_nil
  end

  it "keeps public metric variation while omitting metric internals" do
    report = create(:market_report, :published, slug: "safe-metrics")
    report.market_report_metrics.create!(
      label: "Vacancy rate",
      value: "6.1%",
      unit: "%",
      variation: "-0.3 pp",
      description: "Internal analyst commentary",
      position: 1
    )

    get "/api/v1/market_reports/safe-metrics"

    metric = json_response.dig("data", "report_metrics", 0)
    expect(response).to have_http_status(:ok)
    expect(metric).to include("label" => "Vacancy rate", "value" => "6.1%", "unit" => "%", "variation" => "-0.3 pp")
    expect(metric.keys).to match_array(%w[label value unit variation])
  end

  it "returns only a complete published editorial translation" do
    report = create(:market_report, :published, title: "Relatório", excerpt: "Resumo", body: "Conteúdo")
    report.update!(metadata: report.metadata.to_h.merge(
      "content_locale" => "pt-BR",
      "translations" => {
        "en" => { "status" => "published", "complete" => true, "fields" => { "title" => "Report", "excerpt" => "Summary", "body" => "Content" } },
        "es" => { "status" => "published", "complete" => true, "fields" => { "title" => "Informe" } }
      }
    ))

    get "/api/v1/market_reports/#{report.slug}?locale=en"
    expect(json_response.dig("data", "title")).to eq("Report")
    expect(json_response.dig("data", "locale", "fallback_used")).to be(false)

    get "/api/v1/market_reports/#{report.slug}?locale=es"
    expect(json_response.dig("data", "title")).to eq("Relatório")
    expect(json_response.dig("data", "locale", "fallback_used")).to be(true)
  end
end
