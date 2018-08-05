# frozen_string_literal: true

require 'faraday'
require 'json'

require_relative './es_health_rules/_index'
require_relative './monitor_engine/monitor_engine'

module ESMonitor
  class Monitor
    def initialize()
      url = ENV['ELASTIC_URL'] || 'http://localhost:9200'

      @es_client = Faraday.new({ url: url })
      monitor_indices()
      puts "\n\n======================\n\n"
      monitor_shards()
      puts "\n\n======================\n\n"
      monitor_nodes()
    end

    def monitor_indices
      res = @es_client.get do |req|
        req.url('/_cluster/health')
        req.params = {
          level: 'shards',
          timeout: '2s'
        }
      end
      es_status = JSON.parse(res.body)
      rules = IndicesRules.get_rules()
      MonitorEngine.monitor(es_status, rules)
    end

    def monitor_shards
      res = @es_client.get do |req|
        req.url('/_cluster/state/_all')
        req.params = {
          timeout: '2s'
        }
      end
      es_status = JSON.parse(res.body)
      rules = ShardsRules.get_rules()
      MonitorEngine.monitor(es_status, rules)
    end

    def monitor_nodes
      res = @es_client.get do |req|
        req.url('/_nodes/stats')
        req.params = {
          timeout: '2s'
        }
      end
      es_status = JSON.parse(res.body)
      rules = NodesRules.get_rules()
      MonitorEngine.monitor(es_status, rules)
    end
  end
end
