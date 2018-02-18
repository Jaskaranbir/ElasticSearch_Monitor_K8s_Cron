# frozen_string_literal: true

require_relative '../../monitor_engine'

module ESMonitor
  class WC_Array_ArrayDataOr
    PATTERN = :'___OR'

    def self.get_pattern
      PATTERN
    end

    def self.scan(scan_data, rule, alert_helper)
      is_rule_success = false
      scan_data.each do | data_element |
        if (rule.is_a?(Hash))
          is_rule_success = MonitorEngine._handle_hash_rule(data_element, rule, alert_helper, true, false)
        else
          is_rule_success = MonitorEngine._check_rule(data_element, rule, alert_helper, false, true)
        end
        break if is_rule_success
      end
      alert_helper.alert_optional_array_element_not_found(scan_data, rule) unless is_rule_success

      return is_rule_success
    end
  end
end
