# frozen_string_literal: true

module ESMonitor
  class WC_Array_MathOperation
    BETWEEN_PATTERN = :'___BT'
    EQUALS_PATTERN = :'___EQ'
    GREATER_THAN_PATTERN = :'___GT'
    LESS_THAN_PATTERN = :'___LT'

    PATTERNS = [
      BETWEEN_PATTERN,
      EQUALS_PATTERN,
      GREATER_THAN_PATTERN,
      LESS_THAN_PATTERN
    ]

    def self.get_pattern
      PATTERNS
    end

    def self.scan(scan_data, rule, alert_helper)
      is_valid_rule_type = !rule[1].nil? \
                           && (rule[1].is_a?(Integer) \
                               || rule[1].is_a?(Float))
      raise ArgumentError.new(
        "Invalid data-type for range-compare value at rule: #{rule}." \
        "The value should be an Integer or a Float."
      ) unless is_valid_rule_type
      is_valid_data_type = !scan_data.nil? \
                           && (scan_data.is_a?(Integer) \
                               || scan_data.is_a?(Float))
      return false if !is_valid_data_type
      # First element is always type of operation
      # Next elements are numbers to use for operation
      operation = rule[0]
      is_rule_success = false

      case operation
        when BETWEEN_PATTERN
          is_valid_range_type = !rule[2].nil? \
                            && (rule[2].is_a?(Integer) \
                                || rule[2].is_a?(Float))
          raise ArgumentError.new(
            "Invalid data-type for range-compare value at rule: #{rule}." \
            "The value should be an Integer or a Float."
          ) unless is_valid_range_type
          is_rule_success = scan_data > rule[1] && scan_data < rule[2]
        when EQUALS_PATTERN
          is_rule_success = scan_data == rule[1]
        when GREATER_THAN_PATTERN
          is_rule_success = scan_data > rule[1]
        when LESS_THAN_PATTERN
          is_rule_success = scan_data < rule[1]
      end

      if (is_rule_success)
        alert_helper.revert_state()
      else
        alert_helper.alert_invalid_math_opr(rule, scan_data)
      end
      return is_rule_success
    end
  end
end
