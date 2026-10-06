module NewsletterSegments
  class Matcher
    def initialize(segment)
      @segment = segment
    end

    def scope
      NewsletterSubscriber.subscribed.select { |subscriber| matches?(subscriber) }
    end

    def count
      scope.count
    end

    private

    def matches?(subscriber)
      results = Array(@segment.conditions).map do |condition|
        key = condition["field"] || condition[:field]
        operator = condition["operator"] || condition[:operator] || "equals"
        expected = condition["value"] || condition[:value]
        actual = canonical_value(subscriber, key.to_s)
        compare(actual, operator.to_s, expected)
      end
      @segment.logic_any_rule? ? results.any? : results.all?
    end

    def compare(actual, operator, expected)
      expected_values = expected.is_a?(Array) ? expected.map(&:to_s) : expected.to_s.split(",").map(&:strip)
      case operator
      when "contains" then actual.to_s.downcase.include?(expected.to_s.downcase)
      when "not_contains" then !actual.to_s.downcase.include?(expected.to_s.downcase)
      when "not_equals" then actual.to_s != expected.to_s
      when "in" then expected_values.include?(actual.to_s)
      when "greater_than" then actual.to_f > expected.to_f
      when "greater_than_or_equal" then actual.to_f >= expected.to_f
      when "less_than" then actual.to_f < expected.to_f
      when "less_than_or_equal" then actual.to_f <= expected.to_f
      else actual.to_s == expected.to_s
      end
    end

    def canonical_value(subscriber, key)
      return subscriber.email if key == "email"
      return subscriber.source if key == "source"
      return subscriber.subscribed? if key == "consent"

      subscriber.metadata[key]
    end
  end
end
