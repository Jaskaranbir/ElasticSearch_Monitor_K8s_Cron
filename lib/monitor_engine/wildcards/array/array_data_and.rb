# frozen_string_literal: true

require_relative '../../monitor_engine'

module ESMonitor
  class WC_Array_ArrayDataAnd
    PATTERN = :'___AND'

    def self.get_pattern
      PATTERN
    end

    def self.scan(scan_data, rule, alert_helper)
      is_rule_success = false
      rule = [rule] if rule.is_a?(Hash)
      rule.each do | sub_rule |
        is_rule_success = false
        scan_data.each do | sub_data |
          # Ensure the data types we apply rules on are consistent
          if (sub_rule.is_a?(Hash) && sub_data.is_a?(Hash))
            is_rule_success = MonitorEngine._handle_hash_rule(sub_data, sub_rule, alert_helper, true, false)
          else
            is_rule_success = MonitorEngine._check_rule(sub_data, sub_rule, alert_helper, false)
          end
          break if is_rule_success
        end

        # All values need to be present. Missing value means error.
        alert_helper.alert_array_element_not_found(scan_data, sub_rule) unless (is_rule_success)
      end

      return is_rule_success
    end
  end
end
