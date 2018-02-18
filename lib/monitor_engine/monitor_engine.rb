# frozen_string_literal: true

require_relative './alert_helper'
require_relative './wildcards/_index'

module ESMonitor
  class MonitorEngine
               ANY_MATCH_PATTERN = WC_Hash_AnyMatch.get_pattern
    ARRAY_ARRAY_DATA_AND_PATTERN = WC_Array_ArrayDataAnd.get_pattern
     ARRAY_ARRAY_DATA_OR_PATTERN = WC_Array_ArrayDataOr.get_pattern
             ARRAY_INDEX_PATTERN = WC_Array_ArrayIndex.get_pattern
               HASH_OPTIONAL_KEY = WC_Hash_OptionalKey.get_pattern
                NUM_OPR_PATTERNS = WC_Array_MathOperation.get_pattern
       SPECIAL_HASH_KEY_PATTERNS = [HASH_OPTIONAL_KEY]

    # Only function supposed to be called outside this class
    # All other functions are internal
    def self.monitor(scan_data, rule)
      # This blank hash is our initial error-state and will contain error-info
      _ah = AlertHelper.new({})
      is_rule_success = _check_rule(scan_data, rule, _ah)
      return is_rule_success
    end

    def self._check_rule(scan_data, rule, alert_helper, should_log_error = true, is_array_or_condition = true)
      is_rule_success = false
      rule_data_type = rule.class.name
      scan_data_type = scan_data.class.name

      # If data types for rule and scan_data dont match
      is_rule_hash = rule_data_type == 'Hash' && rule != ANY_MATCH_PATTERN
      if (is_rule_hash && scan_data_type != 'Hash')
        alert_helper.alert_invalid_data_type(rule_data_type, scan_data_type)
        is_rule_success = false

      else
        case rule_data_type
          when 'Array'
            is_rule_success = _handle_array_rule(scan_data, rule, alert_helper, is_array_or_condition, should_log_error)
          when 'Hash'
            is_rule_success = _handle_hash_rule(scan_data, rule, alert_helper, false, should_log_error)
          else
            is_rule_success = scan_data == rule
            if (should_log_error)
              if (is_rule_success)
                alert_helper.revert_state()
              else
                alert_helper.alert_value_mismatch(rule, scan_data)
              end
            end
        end
      end

      # !!!!!!
      # Right now all errors are printed as soon as they occur.
      # But if you would rather print them just once, print the "alert_helper.get" here
      # to get the final object containing all actual and expected values
      return is_rule_success
    end

    def self._handle_hash_rule(
      scan_data, rule, alert_helper,
      should_ignore_not_found = false, should_log_optional_failure = true
    )
      # Assume true by default. Then we set it to false once if some rule fails
      is_rule_success = true
      keys = rule.keys

      WC_Hash_AnyMatch.before_function(keys)

      keys.each do | key |
        next if key == ANY_MATCH_PATTERN
        key_str = key.to_s
        is_sub_rule_success = false

        sub_rule = rule[key]
        alert_helper.set_key(key)
        if (scan_data.is_a?(Hash))
          if (!scan_data[key_str].nil?)
            child_scan_data = scan_data[key_str]
            is_sub_rule_success = _check_rule(child_scan_data, sub_rule, alert_helper)

          elsif (SPECIAL_HASH_KEY_PATTERNS.include?(key))
            case key
              # If the key is present, verify the rules for it
              # If it isn't, we dont throw any errors regarding not found
              when HASH_OPTIONAL_KEY
                WC_Hash_OptionalKey.scan(scan_data, sub_rule, alert_helper)
            end

          elsif (key != ANY_MATCH_PATTERN)
            if (should_ignore_not_found)
              alert_helper.alert__missing_optional_hash() if should_log_optional_failure
              is_sub_rule_success = false
            else
              alert_helper.alert_missing_hash(key, rule)
              is_sub_rule_success = false
            end

          else
            # Most likely some pattern rule. In which case
            # success-status will be decided later
            is_sub_rule_success = true
          end
        else
          is_sub_rule_success = _check_rule(scan_data, sub_rule, alert_helper)
          is_rule_success = false unless is_sub_rule_success
        end
        alert_helper.revert_state()
        # If this is true, but sub-rule was false, set this to false
        is_rule_success = is_sub_rule_success if is_rule_success
      end
      # This is not in above loop under "else" condition because we always want to evaluate it at the end of loop
      # We pass "keys" instead of "rule.keys" because keys is specially sorted array
      # "keys" ensure that this pattern is alwasys contained in end (see WC_Hash_AnyMatch#before_function)
      is_rule_success = WC_Hash_AnyMatch.scan(scan_data, rule, keys, alert_helper) \
                        && is_rule_success
      return is_rule_success
    end

    def self._handle_array_rule(
      scan_data, rule, alert_helper,
      is_or_condition = true, should_log_error = true
    )
      is_rule_success = false
      # Multiple possible values provided
      # In this case one of the values must match
      # (Although this variable simply tracks if multiple values were provided)
      is_option_values = false

      rule.each_with_index do | sub_rule, index |
        if (scan_data.is_a?(Array))
          is_rule_success = _handle_array_data(scan_data, sub_rule, alert_helper)
        # Math operations should not contain unrelated elements in array
        elsif (NUM_OPR_PATTERNS.include?(sub_rule) && index == 0)
          is_rule_success = WC_Array_MathOperation.scan(scan_data, rule, alert_helper)
          # Math operations resolve rule array as whole, so no need to iterate further
          break
        else
          is_option_values = true unless is_option_values
          # Just plain integer / string values, most likely
          # Send it back to parent function for re-evaluation
          is_sub_rule_success = _check_rule(scan_data, sub_rule, alert_helper, false)
          if (is_sub_rule_success)
            is_rule_success = true
            break
          end
        end

        # When using "or" condition, we only check for successfulness of one rule
        # If none of the below conditions is true, then its fail by default:
        # * Atleast one element in array should match expected value
        is_or_cond_success = is_or_condition && is_rule_success
        # * If data is not a "simple" structure, we let above rules decide
        is_simple_scan_data = !scan_data.is_a?(Array) && !scan_data.is_a?(Hash)
        break if is_or_cond_success && is_simple_scan_data
      end

      if (is_option_values && !is_rule_success && should_log_error)
        alert_helper.alert_value_match_not_found(scan_data, rule)
      end

      return is_rule_success
    end

    def self._handle_array_data(scan_data, rule, alert_helper)
      is_rule_success = false

      if (rule.is_a?(Hash))
        keys = rule.keys
        keys.each do | key |
          key_str = key.to_s
          alert_helper.set_key(key)

          is_rule_success = false
          case key
            # We check if "array-index" is present
            # and point rule-check to that index
            when ARRAY_INDEX_PATTERN
              is_rule_success = WC_Array_ArrayIndex.scan(scan_data, rule, alert_helper)
              # Index-Pattern is processed in a single go, no need to iterate Hash further
              break
            when ARRAY_ARRAY_DATA_OR_PATTERN
              is_rule_success = WC_Array_ArrayDataOr.scan(scan_data, rule[key], alert_helper)
            when ARRAY_ARRAY_DATA_AND_PATTERN
              is_rule_success = WC_Array_ArrayDataAnd.scan(scan_data, rule[key], alert_helper)
            else
              is_rule_success = _handle_array_data_other(scan_data, rule[key], key_str, alert_helper)
              break if is_rule_success
          end
        end

      elsif (rule.is_a?(Array))
        is_rule_success = _handle_array_data_array_rule(scan_data, rule, alert_helper)

      else
        is_rule_success = scan_data.include?(rule)
        alert_helper.alert_array_element_not_found(scan_data, rule) unless is_rule_success
      end

      return is_rule_success
    end

    def self._handle_array_data_other(scan_data, rule, key_str, alert_helper)
      is_rule_success = false
      scan_data.each do | sub_data |
        if (sub_data.is_a?(Hash))
          sub_data = sub_data[key_str]
        end
        next if sub_data.nil?
        if (rule.is_a?(Hash))
          is_rule_success = _handle_hash_rule(sub_data, rule, alert_helper)
        else
          is_rule_success = _check_rule(sub_data, rule, alert_helper)
        end
      end

      return is_rule_success
    end

    def self._handle_array_data_array_rule(scan_data, rule, alert_helper)
      failures = []
      rule.each do | sub_rule |
        is_rule_success = false
        is_match_opr = false
        scan_data.each do | data_element |
          if (data_element.is_a?(Array))
            is_rule_success = _handle_array_data(data_element, sub_rule)
          elsif (NUM_OPR_PATTERNS.include?(sub_rule))
            is_match_opr = true
            is_rule_success = WC_Array_MathOperation.scan(data_element, rule, alert_helper)
            # Math operations resolve rule array as whole, so no need to iterate further
            break if is_rule_success
          else
            is_rule_success = _check_rule(data_element, sub_rule)
          end
          break if is_rule_success
        end
        failures.push(
          {'rule' => rule, 'scan_data' => scan_data}
        ) unless is_rule_success
        # Math operations handle array as whole, no need to continue iterating
        break if is_match_opr
      end

      failures.empty?
    end

  end
end
