# frozen_string_literal: true

require_relative '../../monitor_engine'

module ESMonitor
  class WC_Hash_AnyMatch
    PATTERN = :'___*'

    def self.get_pattern
      return PATTERN
    end

    def self.before_function(rule_keys)
      # Move the "*" pattern to end of array so specific rule_keys can be matched first
      any_match_pattern_index = rule_keys.find_index(PATTERN)
      if (!any_match_pattern_index.nil?)
        rule_keys.delete_at(any_match_pattern_index)
        rule_keys.insert(rule_keys.length, PATTERN)
      end
    end

    def self.scan(scan_data, rule, rule_keys, alert_helper)
      is_rule_success = true
      # Since we forced "any match pattern" (if present) to be last
      # We just need to check the last element
      if (rule_keys[rule_keys.length - 1] == PATTERN)
        scan_data_keys = scan_data.keys.select {
          | sd_key | !rule_keys.include?(sd_key.to_sym)
        }

        scan_data_keys.each do | sdk |
          alert_helper.set_key(sdk)
          sub_rule = rule[PATTERN]
          is_sub_rule_success = false
          is_sub_rule_success = MonitorEngine._check_rule(scan_data[sdk], sub_rule, alert_helper)

          is_rule_success = is_sub_rule_success if is_rule_success
          alert_helper.revert_state() unless is_sub_rule_success
        end
      end

      return is_rule_success
    end
  end
end