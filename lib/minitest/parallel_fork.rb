gem 'minitest'
require 'minitest'

module Minitest
  # Set the before_parallel_fork block to the given block
  def self.before_parallel_fork(&block)
    @before_parallel_fork = block
  end

  # Set the after_parallel_fork block to the given block
  def self.after_parallel_fork(i=nil, &block)
    @after_parallel_fork = block
  end

  # Subclass of Assertion for unexpected errors.  UnexpectedError
  # can not be used as it can include undumpable objects.  This
  # class converts all data it needs to plain strings, so that
  # it will be dumpable.
  class DumpableUnexpectedError < Assertion # :nodoc:
    attr_accessor :backtrace

    def initialize(unexpected)
      exception_class_name = unexpected.exception.class.name.to_s
      exception_message = unexpected.exception.message.to_s
      super("#{exception_class_name}: #{exception_message}")
      self.backtrace = unexpected.exception.backtrace.map(&:to_s)
    end

    def message
      bt = Minitest.filter_backtrace(backtrace).join "\n    "
      "#{super}\n    #{bt}"
    end

    def result_label
      "Error"
    end
  end

  module Unparallelize
    define_method(:run_one_method, &Minitest::Test.method(:run_one_method))
  end
  
  def self.parallel_fork_stat_reporter(reporter)
    reporter.reporters.detect{|rep| rep.is_a?(StatisticsReporter)}
  end

  # Override __run to use a child forks to run the speeds, which
  # allows for parallel spec execution on MRI.
  def self.__run(reporter, options)
    suites = Runnable.runnables.shuffle
    stat_reporter = parallel_fork_stat_reporter(reporter)

    n = (ENV['NCPU'] || 4).to_i
    reads = []
    if defined?(@before_parallel_fork)
      @before_parallel_fork.call
    end
    n.times do |i|
      read, write = IO.pipe.each{|io| io.binmode}
      reads << read
      fork do
        read.close
        if defined?(@after_parallel_fork)
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
        data[-1] = data[-1].map do |res|
          [res.name, res.failures.map{|f| f.is_a?(UnexpectedError) ? DumpableUnexpectedError.new(f) : f}]
        end

        write.write(Marshal.dump(data))
        write.close
      end
      write.close
    end
    Process.waitall

    Thread.new do
      reads.each do |r|
        data = r.read
        r.close
        count, assertions, results = Marshal.load(data)
        stat_reporter.count += count
        stat_reporter.assertions += assertions
        results.map! do |name, failures|
          runnable = Test.new(name)
          runnable.failures.concat(failures.map{|f| f.is_a?(DumpableUnexpectedError) ? UnexpectedError.new(f) : f})
          runnable
        end
        stat_reporter.results.concat(results)
      end
    end.join

    nil
  end
end
