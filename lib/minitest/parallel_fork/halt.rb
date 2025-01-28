module Minitest::ParallelForkHalt
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

      # Halt if this child process requested an exit,
      # Or other child processes requested an exit.
      break if @parallel_fork_stop
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
            # If halt is requested, signal other children to halt
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
