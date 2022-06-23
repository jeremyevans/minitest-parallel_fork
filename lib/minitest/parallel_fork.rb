gem 'minitest'
require 'minitest'

module Minitest
  # Set the before_parallel_fork block to the given block
  def self.before_parallel_fork(&block)
    @before_parallel_fork = block
  end
  @before_parallel_fork = nil

  # Set the after_parallel_fork block to the given block
  def self.after_parallel_fork(i=nil, &block)
    @after_parallel_fork = block
  end
  @after_parallel_fork = nil

  # Set the on_parallel_fork_marshal_failure block to the given block
  def self.on_parallel_fork_marshal_failure(&block)
    @on_parallel_fork_marshal_failure = block
  end
  @on_parallel_fork_marshal_failure = nil

  module Unparallelize
    define_method(:run_one_method, &Minitest::Test.method(:run_one_method))
  end
  
  def self.parallel_fork_stat_reporter(reporter)
    reporter.reporters.detect do |rep|
      %w'count assertions results count= assertions='.all?{|meth| rep.respond_to?(meth)}
    end
  end

  # Override __run to use a child forks to run the speeds, which
  # allows for parallel spec execution on MRI.
  def self.__run(reporter, options)
    suites = Runnable.runnables.shuffle
    stat_reporter = parallel_fork_stat_reporter(reporter)

    n = (ENV['NCPU'] || 4).to_i
    reads = []
    if @before_parallel_fork
      @before_parallel_fork.call
    end
    n.times do |i|
      read, write = IO.pipe.each{|io| io.binmode}
      reads << read
      Process.fork do
        read.close
        if @after_parallel_fork
          @after_parallel_fork.call(i)
        end

        p_suites = []
        suites.each_with_index{|s, j| p_suites << s if j % n == i}
        p_suites.each do |s|
          if s.is_a?(Minitest::Parallel::Test::ClassMethods)
            s.extend(Unparallelize)
          end

          s.run(reporter, options)
        end

        data = %w'count assertions results'.map{|meth| stat_reporter.send(meth)}

        # :nocov:
        # Support old minitest versions that don't use Minitest::Result automatically
        if data[-1].any?{|result| !result.is_a?(Minitest::Result)}
          data[-1] = data[-1].map do |result|
            Minitest::Result.from(result)
          end
        end
        # :nocov:

        data[-1].each do |result|
          result.failures.each do |failure|
            if failure.is_a?(Minitest::UnexpectedError)
              e = failure.error
              begin
                Marshal.dump(e)
              rescue TypeError
                # :nocov:
                # Support old minitest not automatically using dumpable exceptions
                e2 = RuntimeError.new("Wrapped undumpable exception for: #{e.class}: #{e.message}")
                e2.set_backtrace(e.backtrace)
                failure.error = e2
                # :nocov:
              end
            end
          end
        end

        write.write(Marshal.dump(data))
        write.close
      end
      write.close
    end

    reads.map{|read| Thread.new(read, &:read)}.map(&:value).each do |data|
      begin
        count, assertions, results = Marshal.load(data)
      rescue ArgumentError
        if @on_parallel_fork_marshal_failure
          @on_parallel_fork_marshal_failure.call
        end
        raise
      end
      stat_reporter.count += count
      stat_reporter.assertions += assertions
      stat_reporter.results.concat(results)
    end

    nil
  end
end
