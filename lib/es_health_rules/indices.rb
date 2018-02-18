# frozen_string_literal: true
module ESMonitor
  class IndicesRules
    def self.get_rules()
      {
        status: ['yellow', 'green'],
        timed_out: false,
        number_of_nodes: [:'___GT', 1],
        number_of_data_nodes: [:'___GT', 1],
        active_shards: [:'___GT', 0],
        unassigned_shards: 0,
        delayed_unassigned_shards: 0,
        indices: [
          {
            status: ['yellow', 'green'],
            unassigned_shards: 0,
            shards: [
              {
                status: ['yellow', 'green'],
                active_shards: [:'___GT', 1],
                unassigned_shards: 0,
              }
            ]
          }
        ]
      }
    end
  end
end
