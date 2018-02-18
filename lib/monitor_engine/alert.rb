# frozen_string_literal: true

require 'json'

module ESMonitor
  class Alert
    def self.transport_alert(error_obj, error_paths)
      out = {
        error_obj: error_obj,
        error_path: error_paths
      }
      puts out.to_json
    end
  end
end
