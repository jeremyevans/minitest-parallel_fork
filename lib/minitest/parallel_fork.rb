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

  def parallel_fork_stat_reporter(reporter)
    reporter.reporters.detect do |rep|
      %w'count assertions results count= assertions='.all?{|meth| rep.respond_to?(meth)}
    end
  end

  def parallel_fork_suites
    Minitest::Runnable.runnables.shuffle
  end

  def parallel_fork_setup_children(suites, reporter, options)
    stat_reporter = parallel_fork_stat_reporter(reporter)

    if @before_parallel_fork
      @before_parallel_fork.call
    end

    n = parallel_fork_number
    n.times.map do |i|
      read, write = IO.pipe.each{|io| io.binmode}
      pid = Process.fork do
        read.close
        if @after_parallel_fork
          @after_parallel_fork.call(i)
        end

        p_suites = []
        suites.each_with_index{|s, j| p_suites << s if j % n == i}
        p_suites.each do |s|
          if s.is_a?(Minitest::Parallel::Test::ClassMethods)
            s.extend(Minitest::Unparallelize)
          end

          s.run(reporter, options)
        end

        data = %w'count assertions results'.map{|meth| stat_reporter.send(meth)}
        write.write(Marshal.dump(data))
        write.close
      end
      write.close
      [pid, read]
    end
  end

  def parallel_fork_wait_for_children(data, reporter)
    data.map{|_pid, read| Thread.new(read, &:read)}.map(&:value).each do |data|
      begin
        count, assertions, results = Marshal.load(data)
      rescue ArgumentError
        if @on_parallel_fork_marshal_failure
          @on_parallel_fork_marshal_failure.call
        end
        raise
      end
      reporter.reporters.each do |rep|
        next unless %w'count assertions results count= assertions='.all?{|meth| rep.respond_to?(meth)}
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
