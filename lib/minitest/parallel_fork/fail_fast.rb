require_relative '../parallel_fork'

module Minitest::ParalleForkFailFast
  def run_after_parallel_fork_hook(i)
    super
    Signal.trap(:USR1) do
      @parallel_fork_stop = true
    end
  end

  def parallel_fork_data_to_marshal
    super << @parallel_fork_stop
  end

  def parallel_fork_data_from_marshal(data)
    data = Marshal.load(data)
    @parallel_fork_stop = true if data.pop
    data
  end

  def parallel_fork_run_test_suites(suites, reporter, options)
    suites.each do |suite|
      parallel_fork_run_test_suite(suite, reporter, options)

      # Fail fast if this child process had a failure,
      # Or the USR1 signal was received indicating other child processes had a failure.
      break if @parallel_fork_stop
    end
  end

  def parallel_fork_run_test_suite(suite, reporter, options)
    super


    if parallel_fork_stat_reporter.results.any?{|r| !r.failure.is_a?(Minitest::Skip)}
      # At least one failure or error, mark as failing fast
      @parallel_fork_stop = true
    end
  end

  def parallel_fork_child_data(data)
    threads = {}
    data.each{|pid, read| threads[pid] = Thread.new(read, &:read)}
    results = []

    while sleep(0.01) && !threads.empty?
      threads.to_a.each do |pid, thread|
        unless thread.alive?
          threads.delete(pid)
          results << parallel_fork_data_from_marshal(thread.value)

          if @parallel_fork_stop
            # If any child failed fast, signal other children to fail fast
            threads.each_key do |pid|
              Process.kill(:USR1, pid)
            end

            # Set a flag indicating that all child processes have been signaled
            @parallel_fork_stop = :FINISHED
          end
        end
      end
    end

    results
  end
end

Minitest.singleton_class.prepend(Minitest::ParalleForkFailFast)
