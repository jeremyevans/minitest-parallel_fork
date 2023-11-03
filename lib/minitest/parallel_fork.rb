require 'minitest'

module Minitest::Unparallelize
  define_method(:run_one_method, &Minitest::Test.method(:run_one_method))
end

module Minitest
  @before_parallel_fork = nil
  @after_parallel_fork = nil
  @on_parallel_fork_marshal_failure = nil
end

class << Minitest
  # Set the before_parallel_fork block to the given block
  def before_parallel_fork(&block)
    @before_parallel_fork = block
  end

  # Set the after_parallel_fork block to the given block
  def after_parallel_fork(i=nil, &block)
    @after_parallel_fork = block
  end

  # Set the on_parallel_fork_marshal_failure block to the given block
  def on_parallel_fork_marshal_failure(&block)
    @on_parallel_fork_marshal_failure = block
  end

  attr_reader :parallel_fork_stat_reporter

  def set_parallel_fork_stat_reporter(reporter)
    @parallel_fork_stat_reporter = reporter.reporters.detect do |rep|
      %w'count assertions results count= assertions='.all?{|meth| rep.respond_to?(meth)}
    end
  end

  def parallel_fork_suites
    Minitest::Runnable.runnables.shuffle
  end

  def run_before_parallel_fork_hook
    if @before_parallel_fork
      @before_parallel_fork.call
    end
  end

  def run_after_parallel_fork_hook(i)
    if @after_parallel_fork
      @after_parallel_fork.call(i)
    end
  end

  def parallel_fork_data_to_marshal
    %i'count assertions results'.map{|meth| parallel_fork_stat_reporter.send(meth)}
  end

  def parallel_fork_data_from_marshal(data)
    Marshal.load(data)
  rescue ArgumentError
    if @on_parallel_fork_marshal_failure
      @on_parallel_fork_marshal_failure.call
    end
    raise
  end

  def parallel_fork_run_test_suites(suites, reporter, options)
    suites.each do |suite|
      parallel_fork_run_test_suite(suite, reporter, options)
    end
  end

  def parallel_fork_run_test_suite(suite, reporter, options)
    if suite.is_a?(Minitest::Parallel::Test::ClassMethods)
      suite.extend(Minitest::Unparallelize)
    end

    suite.run(reporter, options)
  end

  def parallel_fork_setup_children(suites, reporter, options)
    set_parallel_fork_stat_reporter(reporter)
    run_before_parallel_fork_hook

    n = parallel_fork_number
    n.times.map do |i|
      read, write = IO.pipe.each{|io| io.binmode}
      pid = Process.fork do
        read.close
        run_after_parallel_fork_hook(i)

        p_suites = []
        suites.each_with_index{|s, j| p_suites << s if j % n == i}
        parallel_fork_run_test_suites(p_suites, reporter, options)

        write.write(Marshal.dump(parallel_fork_data_to_marshal))
        write.close
      end
      write.close
      [pid, read]
    end
  end

  def parallel_fork_child_data(data)
    data.map{|_pid, read| Thread.new(read, &:read)}.map(&:value).map{|data| parallel_fork_data_from_marshal(data)}
  end

  def parallel_fork_wait_for_children(child_info, reporter)
    parallel_fork_child_data(child_info).each do |data|
      count, assertions, results = data
      reporter.reporters.each do |rep|
        next unless %i'count assertions results count= assertions='.all?{|meth| rep.respond_to?(meth)}
        rep.count += count
        rep.assertions += assertions
        rep.results.concat(results)
      end
    end
  end

  def parallel_fork_number
    (ENV['NCPU'] || 4).to_i
  end

  # Override __run to use a child forks to run the speeds, which
  # allows for parallel spec execution on MRI.
  def __run(reporter, options)
    parallel_fork_wait_for_children(parallel_fork_setup_children(parallel_fork_suites, reporter, options), reporter)
    nil
  end
end
