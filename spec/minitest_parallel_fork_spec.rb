if ENV.delete('COVERAGE')
  require_relative 'simplecov_helper'
end

ENV['MT_NO_PLUGINS'] = '1'
require 'minitest/global_expectations/autorun'

ENV['NCPU'] = '4'

require 'open3'

describe 'minitest/parallel_fork' do
  def run_mpf(*env_keys)
    env_keys.each{|k| ENV[k] = '1'}
    t = Time.now
    output = `#{ENV['RUBY']} -I lib spec/minitest_parallel_fork_#{@example_prefix}example.rb 2>&1`
    [output, Time.now - t]
  ensure
    env_keys.each{|k| ENV.delete(k)}
  end

  [[nil, ''],
   ['MPF_PARALLELIZE_ME', ' when parallelize_me! is used'],
   ['MPF_TEST_ORDER_PARALLEL', ' when test_order parallel is used'],
   ['MPF_NO_HOOKS', ' when no hooks are used']
  ].each do |env_key, msg|
    it "should execute in parallel#{msg}" do
      output, time = run_mpf(*env_key)
      time.must_be :<, 4
      time.must_be :>, 1
      output.must_include '20 runs, 8 assertions, 4 failures, 8 errors, 4 skips'

      unless env_key == 'MPF_NO_HOOKS'
        output.must_include ':parent'
        4.times do |i|
          output.must_include ":child#{i}a"
        end
      end
    end
  end

  [[nil, ''],
   ['MPF_PARALLELIZE_ME', ' when parallelize_me! is used'],
   ['MPF_TEST_ORDER_PARALLEL', ' when test_order parallel is used'],
   ['MPF_MINITEST_HOOKS', ' when minitest/hooks is used'],
   ['MPF_FAIL_FAST', ' when using fail fast support'],
  ].each do |env_key, msg|
    it "should execute in parallel#{msg} with passing test suite" do
      @example_prefix = 'pass_'
      output, = run_mpf(*env_key)
      output.sub!(/, \d+ assertions/, ', 64 assertions') if Minitest::VERSION >= '6' && env_key == 'MPF_MINITEST_HOOKS'
      output.must_include '40 runs, 64 assertions, 0 failures, 0 errors, 8 skips'
    end
  end

  it "should handle marshal failures without on_parallel_fork_marshal_failure" do
    output, time = run_mpf('MPF_TEST_CHILD_FAILURE', 'MPF_NO_HOOKS')
    time.must_be :<, 4
    output.must_include 'marshal data too short'
  end

  it "should call on_parallel_fork_marshal_failure on failure" do
    output, time = run_mpf('MPF_TEST_CHILD_FAILURE')
    time.must_be :<, 4
    output.must_include ':child-failurea'
    output.must_include 'marshal data too short'
  end

  it "should handle failures in *_all methods when using minitest-hooks" do
    output, time = run_mpf('MPF_MINITEST_HOOKS')
    time.must_be :<, 4
    output.sub!(/, \d+ assertions/, ', 8 assertions') if Minitest::VERSION >= '6'
    output.must_include '23 runs, 8 assertions, 4 failures, 10 errors, 4 skips'
  end

  it "should support several statistics reporters" do
    output, time = run_mpf('MPF_SEVERAL_STATISTICS_REPORTERS')
    time.must_be :<, 4
    output.must_include '20 runs, 8 assertions, 4 failures, 8 errors, 4 skip'
    output.must_include 'Stats: 20R, 8A, 4F, 8E, 4S'
  end

  it "should stop all serial executions when and Interrupt is raised" do
    @example_prefix = 'fail_fast_'
    output, time = run_mpf
    time.must_be :<, 1
    output.must_include '4 runs, 7 assertions, 1 failures, 0 errors, 0 skips'
    output.wont_include 'not_executed'
  end

  it "should force stop all forks with 2x interrupt" do
    command = "#{ENV['RUBY']} -I lib spec/minitest_parallel_fork_interrupt_example.rb"

    stdout = nil
    stderr = nil
    Open3.popen3(command) do |stdin, out, err, wait_thr|
      stdin.close
      sleep 1
      Process.kill('INT', wait_thr.pid)
      sleep 0.2
      begin
        Process.kill('INT', wait_thr.pid)
      rescue Errno::ESRCH
        # Already exited
      end
      wait_thr.value.exitstatus.must_equal 1
      stdout = out.read
      stderr = err.read
    end

    stdout.must_include "Run options: --seed"
    stdout.must_include "# Running:"
    stderr.must_include "Interrupted.\nExiting ...\nInterrupt again to exit immediately."
  end
end
