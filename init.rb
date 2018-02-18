# frozen_string_literal: true

require_relative 'lib/es_monitor'

ESMonitor::Monitor.new if $PROGRAM_NAME == __FILE__
