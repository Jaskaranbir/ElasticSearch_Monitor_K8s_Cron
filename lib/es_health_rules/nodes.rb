# frozen_string_literal: true
module ESMonitor
  class NodesRules
    def self.get_rules()
      {
        _nodes: {
          failed: 0
        },
        nodes: {
          '___*': {
            indices: {
              indexing: {
                index_failed: 0
              }
            },
            os: {
              cpu: {
                # CPU usage should be less than 85%
                percent: [:'___LT', 85]
              },
              mem: {
                used_percent: [:'___LT', 85]
              }
            },
            ingest: {
              total: {
                failed: 0
              }
            }
          }
        }
      }
    end
  end
end
