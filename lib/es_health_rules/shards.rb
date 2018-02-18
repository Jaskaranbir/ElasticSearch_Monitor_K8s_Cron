# frozen_string_literal: true
module ESMonitor
  class ShardsRules
    def self.get_rules()
      {
        metadata: {
          indices: {
            '___*': {
              state: 'open',
              settings: {
                index: {
                  number_of_shards: [:'___GT', 1],
                  number_of_replicas: [:'___GT', 1],
                }
              }
            }
          }
        },
        routing_table: {
          indices: {
            '___*': {
              shards: {
                '___*': [
                  {
                    state: 'started'
                  }
                ]
              }
            }
          }
        }
      }
    end
  end
end
