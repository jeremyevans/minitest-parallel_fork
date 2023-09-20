module Minitest
  module StatRep
    class Reporter < StatisticsReporter
      def report
        super
        io.puts "Stats: #{count}R, #{assertions}A, #{failures}F, #{errors}E, #{skips}S"
      end
    end
  end
end

module Minitest
  # Hook called from MiniTest's plugin system on run.
  def self.plugin_statrep_init(options)
    if ENV['MPF_SEVERAL_STATISTICS_REPORTERS']
      self.reporter << Minitest::StatRep::Reporter.new(options[:io], options)
    end
  end
end
