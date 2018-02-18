# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'es_monitor/version'

Gem::Specification.new do |spec|
  spec.name          = 'es_monitor'
  spec.version       = ESMonitor::VERSION
  spec.authors       = ['Jaskaranbir Dhillon']
  spec.email         = ['jaskaranbir.dhillon@gmail.com']

  spec.summary       = 'Monitors ES-Cluster status'
  spec.description   = 'Microservice that monitors ElasticSearch cluster status'
  spec.homepage      = 'http://idk'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'http://www.rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files         = Dir['lib/**/*'] + %w[init.rb README.md]
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
