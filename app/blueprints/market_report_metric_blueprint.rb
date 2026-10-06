class MarketReportMetricBlueprint < Blueprinter::Base
  identifier :id

  fields :taxonomy_term_id, :label, :value, :unit, :variation, :position, :featured, :description, :metadata

  field :metric_type do |metric|
    metric.taxonomy_term&.slice(:id, :name, :slug, :kind)
  end
end
