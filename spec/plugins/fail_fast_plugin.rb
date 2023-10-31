# frozen_string_literal: true

require 'minitest'

module Minitest
  def self.plugin_fail_fast_options opts, _options
    FailFastReporter.fail_fast!
    puts 'fast_fail_plugin loaded'
  end

  def self.plugin_fail_fast_init options
    if FailFastReporter.fail_fast?
      io = options.fetch(:io, $stdout)
      self.reporter.reporters << FailFastReporter.new(io, options)
    end
  end

  class FailFastReporter < Reporter
    def self.fail_fast!
      @fail_fast = true
    end

    def self.fail_fast?
      @fail_fast ||= false
    end

    def record result
      if result.failures.reject { |failure| failure.is_a?(Minitest::Skip) }.any?
        io.puts
        raise Interrupt
      else
        super
      end
    end
  end
end
