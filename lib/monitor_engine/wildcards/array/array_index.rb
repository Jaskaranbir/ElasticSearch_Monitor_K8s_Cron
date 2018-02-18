# frozen_string_literal: true

require_relative '../../monitor_engine'

module ESMonitor
  class WC_Array_ArrayIndex
    PATTERN = :'___ARRAY_INDEX'
    VALUE_PATTERN = :'___VALUE'

    def self.get_pattern
      PATTERN
    end

    def self.scan(scan_data, rule, alert_helper)
      index = rule[PATTERN]

      raise ArgumentError.new(
        '___ARRAY_INDEX needs to be an Integer.'
      ) unless index.is_a?(Integer)
      raise ArgumentError.new(
        '___index-rule key not present. It indicate rules to be applied to index.'
      ) unless rule.key?(VALUE_PATTERN)

      alert_helper.add_custom_error_data({
        '______at_index': index
      })

      value_rule = rule[VALUE_PATTERN]
      is_rule_success = MonitorEngine._check_rule(scan_data[index], value_rule, alert_helper)
      return is_rule_success
    end
  end
end
