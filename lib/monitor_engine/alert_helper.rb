# frozen_string_literal: true

require 'json'
require_relative './alert'
require_relative './wildcards/_index'

module ESMonitor
  # This class is responsible for building the error-object
  # It makes error-object's structure match the original scan-data structure
  class AlertHelper
    # Errors occuring at root of Hash are appended to this key
    ROOT_KEY = :'___root'
    # Keys which should display errors as Array containing error Hashes, instead of just Hash
    # This is used where multiple errors can occur under single Hash key
    ARRAY_ERROR_KEYS = [WC_Array_ArrayIndex.get_pattern]

    def initialize(obj, key = ROOT_KEY)
      # Stores our errors
      @hash_obj = obj
      # The current key being used in rule
      @key = key
      # Initial state
      @hash_states = [{ state: @hash_obj, key: @key }]
      # Stores which elements were expected to be found in array, but were missing
      # Only stores for current key. Change in key resets this
      @missing_array_elements = []
      # Tracks nesting level inside Hash
      @nest_level = 1
      # Tracks Hash path while recursion is in progress
      # This is used to display error-location
      @hash_path = []
      # Stores Hash key-path for every error
      @error_paths = []
      # Stores key for which the last error occured.
      @last_error_key = ROOT_KEY
      # In case some additional custom data needs to be included with error
      # This is only used when an error occurs and resets once the error gets logged
      @error_custom_data = {}
      @last_key = false
    end

    def get
      @hash_states.empty? ? @hash_obj : @hash_states[0][:state]
    end

    def add_custom_error_data(error_data_obj)
      raise ArgumentError.new(
        'Error object provided for adding custom error info should be a Hash.'
      ) unless error_data_obj.is_a?(Hash)
      @error_custom_data.merge!(error_data_obj)
    end

    def set_key(key, is_array_obj = false)
      @last_key = @key
      @key = key
      @last_error_key = false unless @key == @last_error_key
      if (is_array_obj)
        @hash_obj[@key] = []
        _add_state()
      elsif (@hash_obj.is_a?(Hash) && !@hash_obj.key?(@key))
        @hash_obj[@key] = {}
        _add_state()
      end
    end

    def _add_state
      @hash_states.push({ state: @hash_obj, key: @key })
      @hash_path.push(@key)
      @hash_obj = @hash_obj[@key]
      @missing_array_elements = []
      @nest_level += 1
    end

    def revert_state(should_revert = true, is_nest_level_affected = true)
      if (should_revert)
        state = @hash_states.pop()
        # If state is nil, some rule failed
        # So lets just account for that
        if (state)
          @last_error_key = false
          @hash_obj = state[:state]
          @last_key = @key
          @key = state[:key]
          @hash_path.pop()

          # To keep nested level consistent
          if (is_nest_level_affected)
            @nest_level -= 1
          else
            @hash_states.push(state)
          end
        end
      end
      _remove_empty_keys()
    end

    def alert_value_mismatch(expected, got)
      _create_alert({
        '______expected': expected,
        '______got': got
      })
    end

    def alert_array_element_not_found(got_array, missing_value)
      should_update_error_path = false
      if (@key == :'___AND')
        revert_state() # Remove '___AND' key
        @key = ''
        should_update_error_path = true
      end
      got_array = [got_array.to_s] unless got_array.is_a?(Array)
      @missing_array_elements.push(missing_value)
      _create_alert({
        '______array_elements_not_found': @missing_array_elements,
        '______got_array': got_array
      }, should_update_error_path)
    end

    def alert_optional_array_element_not_found(data_array, rule_array)
      should_update_error_path = false
      if (@key == :'___OR')
        revert_state() # Remove '___OR' key
        @key = ''
        should_update_error_path = true
      end
      _create_alert({
        '______expected_atleast_one_value_from': rule_array,
        '______got_array': data_array
      }, should_update_error_path)
    end

    def alert_value_match_not_found(match_value, values)
      _create_alert({
        '______no_match_found_from_values': values,
        '______expected_value': match_value
      })
    end

    def alert_missing_hash(missing_key, data_hash_obj)
      # We remove last element in path, as its the element whose path is missing
      location = @hash_states[0..(@hash_states.length - 2)]
                 .map{ | e | e[:key] }.join(".")
      _create_alert({
        '______key_not_found': missing_key,
        '______at_location': location
      })
    end

    def alert_invalid_data_type(expected_type, got_type)
      _create_alert({
        '______expected_data_type': expected_type,
        '______got_data_type': got_type
      })
    end

    def alert_invalid_math_opr(operation, value)
      _create_alert({
        '______math_operation_failure': operation,
        '______got_value': value
      })
    end

    # To be used to validate state on unsuccessful optional rule
    # So no alert is actually printed/added, but just the state is reverted
    def alert__missing_optional_hash
      revert_state()
      _remove_empty_keys()
      revert_state()
      _remove_empty_keys()
    end

    def _create_alert(error_value, should_update_error_path = true)
      _remove_empty_keys()
      should_update_error_path = _handle_error_push(error_value, should_update_error_path)

      if (should_update_error_path || @error_paths.empty?)
        error_path = @hash_path.empty? ? ROOT_KEY : @hash_path.join('.')
        @error_paths.push(error_path)
      end

      error_obj = @hash_states.empty? ? @hash_obj : @hash_states[0][:state]

      out = {
        error_obj: error_obj,
        error_paths: @error_paths
      }
      Alert.transport_alert(error_obj, @error_paths)
      return out
    end

    # Handles pushing final errors to error object (hash_obj)
    # Returns false is error_path should not be updated
    # Otherwise returns whatever was specified in regards to updating error_path
    # Error path is not updated when there are multiple errors at same key
    def _handle_error_push(error_value, should_update_error_path)
      unless (@error_custom_data.empty?)
        error_value.merge!(@error_custom_data)
        @error_custom_data = {}
      end

      if (@last_error_key == @key)
        if (@hash_obj.is_a?(Hash))
          @hash_obj.merge!(error_value)
        elsif (@hash_obj.is_a?(Array))
          @hash_obj.push(error_value)
        end
        should_update_error_path = false
      elsif !(error_value.empty?)
        if (@hash_obj.is_a?(Hash))
          # If a key already contains errors, merging as object might override the same error.
          # So the error key is converted into an array first,
          # and error is pushed to array as Hash-element
          if (ARRAY_ERROR_KEYS.include?(@key))
            is_root_level = @last_key == ROOT_KEY
            # We are transforming from Hash to Array, so keep previous Hash element
            # Basically convert current state from Hash to Array containing Hash
            revert_state()
            prev_error_value = @hash_obj
            revert_state()
            # We overwrite root level to remove keys that are included in ARRAY_ERROR_KEYS
            # This is because there is no previous state stored to switch to at root level
            # On nested (non-root) level, we can switch to previous states to remove those keys
            if (ARRAY_ERROR_KEYS.include?(@key) || is_root_level)
              @hash_obj = []
              @hash_states.push({ state: @hash_obj, key: @key })
            elsif !(ARRAY_ERROR_KEYS.include?(@key))
              set_key(@key, true)
            end

            @hash_obj.push(error_value)
          else
            @hash_obj.merge!(error_value)
          end
        elsif (@hash_obj.is_a?(Array))
          should_update_error_path = false
          @hash_obj.push(error_value)
        end
      end
      @last_error_key = @key
      return should_update_error_path
    end

    def _remove_empty_keys
      return unless @hash_obj.is_a?(Hash)
      # Remove empty keys (most likely successfull rules)
      @hash_obj.keys.each do | k |
        obj = @hash_obj[k]
        is_valid_data = obj.is_a?(String) || obj.is_a?(Array) || obj.is_a?(Hash)
        @hash_obj.delete(k) if (obj && is_valid_data && obj.empty?)
      end
    end

  end
end
