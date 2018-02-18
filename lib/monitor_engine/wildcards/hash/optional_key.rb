# frozen_string_literal: true

require_relative '../../monitor_engine'

module ESMonitor
  class WC_Hash_OptionalKey
    PATTERN = :'___OPTIONAL'

    def self.get_pattern
      PATTERN
    end

    def self.scan(scan_data, rule, alert_helper)
      raise ArgumentError.new(
        '___OPTIONAL can only correspond to a Hash.'
      ) unless rule.is_a?(Hash)
      # Revert the key to show "x" instead of "___OPTIONAL.x" in error structure
      alert_helper.revert_state()
      # Another revert to reassign error state-key without "___OPTIONAL"
      alert_helper.revert_state()
      is_sub_rule_success = MonitorEngine._handle_hash_rule(scan_data, rule, alert_helper, true)
    end
  end
end
