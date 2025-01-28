require_relative 'halt'
require_relative '../parallel_fork'

module Minitest::ParalleForkFailFast
  include Minitest::ParallelForkHalt

  def parallel_fork_run_test_suite(suite, reporter, options)
    super

    if parallel_fork_stat_reporter.results.any?{|r| !r.failure.is_a?(Minitest::Skip)}
      # At least one failure or error, mark as failing fast
      @parallel_fork_stop = true
    end
  end
end

Minitest.singleton_class.prepend(Minitest::ParalleForkFailFast)
