gem 'minitest'
require 'minitest'
require 'io/wait'

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

    processes =
      n.times.map { |i|
        read, write = IO.pipe.each{|io| io.binmode}
        reads << read
        pid = Process.fork do
          interrupted = false
          killed = false

          Signal.trap('USR1') { |_|
            killed = true
          }

          read.close
          if @after_parallel_fork
            @after_parallel_fork.call(i)
          end

          p_suites = []
          suites.each_with_index{|s, j| p_suites << s if j % n == i}
          p_suites.each do |s|
            break if killed

            if s.is_a?(Minitest::Parallel::Test::ClassMethods)
              s.extend(Unparallelize)
            end

            begin
              s.run(reporter, options)
            rescue Interrupt => _
              interrupted = true
              warn "Failed test #{s}"
              warn 'Interrupted. Exiting...'
              break
            end
          end

          data = %w'count assertions results'.map{|meth| stat_reporter.send(meth)}
          data << interrupted
          write.write(Marshal.dump(data))
          write.close
        end
        write.close
        [pid, read]
      }

    # TODO: Guard with a mutex? It's not **really** necessary I guess.
    aborted = []
    processes
      .map { |pid, read|
        thread = Thread.new(pid, read, aborted) { |pid, read, aborted|
          begin
            res = read.wait(1)
          end while !res && aborted.empty?

          if !aborted.empty? && !aborted.include?(pid) # ruby < 2.5 does not like `none?`
            Process.kill('USR1', pid)
          end
          data = read.read
          begin
            count, assertions, results, interrupted = Marshal.load(data)
            aborted << pid if interrupted
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
        }
      }
      .map(&:join)
    nil
  end
end
