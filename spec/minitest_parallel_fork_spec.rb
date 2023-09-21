if ENV.delete('COVERAGE')
  require_relative 'simplecov_helper'
end

ENV['MT_NO_PLUGINS'] = '1'
gem 'minitest'
require 'minitest/global_expectations/autorun'

ENV['NCPU'] = '4'

describe 'minitest/parallel_fork' do
  def run_mpf(*env_keys)
    env_keys.each{|k| ENV[k] = '1'}
    t = Time.now
    output = `#{ENV['RUBY']} -I lib spec/minitest_parallel_fork_example.rb 2>&1`
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
    output.must_include '23 runs, 8 assertions, 4 failures, 10 errors, 4 skips'
  end

  it "should support several statistics reporters" do
    output, time = run_mpf('MPF_SEVERAL_STATISTICS_REPORTERS')
    time.must_be :<, 4
    output.must_include '20 runs, 8 assertions, 4 failures, 8 errors, 4 skip'
    output.must_include 'Stats: 20R, 8A, 4F, 8E, 4S'
  end
end
