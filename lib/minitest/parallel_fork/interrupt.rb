require_relative 'halt'
require_relative '../parallel_fork'

module Minitest
  @parallel_fork_child_pids ||= []
end

module Minitest::ParallelForkInterrupt
  include Minitest::ParallelForkHalt

  def run_before_parallel_fork_hook
    Signal.trap(:INT) do
      Signal.trap(:INT) do
        parallel_fork_kill_all :KILL
      end
      puts "\nInterrupted."
      puts 'Exiting ...'
      puts 'Interrupt again to exit now.'
      at_exit { exit 130 }
      parallel_fork_kill_all :USR1
    end
  end

  def run_after_parallel_fork_hook(i)
    super
    Signal.trap(:INT, 'IGNORE')
  end

  def run_after_parallel_fork_setup_hook(pid)
    super
    @parallel_fork_child_pids << pid
  end

  def parallel_fork_kill_all(signal)
    @parallel_fork_child_pids.each do |pid|
      Process.kill(signal, pid)
    rescue Errno::ESRCH
      # Process already terminated
    end
  end

end

Minitest.singleton_class.prepend(Minitest::ParallelForkInterrupt)
