ENV['MT_NO_PLUGINS'] = '1'
gem 'minitest'
require 'minitest/global_expectations/autorun'

describe 'minitest/parallel_fork' do
  [[nil, ''],
   ['MPF_PARALLELIZE_ME', ' when parallelize_me! is used'],
   ['MPF_TEST_ORDER_PARALLEL', ' when test_order parallel is used']
  ].each do |env_key, msg|
    it "should execute in parallel#{msg}" do
      t = Time.now
      ENV['NCPU'] = '4'
      ENV[env_key] = '1' if env_key
      output = `#{ENV['RUBY']} -I lib spec/minitest_parallel_fork_example.rb`
      ENV.delete(env_key) if env_key

      time = (Time.now - t)
      time.must_be :<, 4
      time.must_be :>, 1
      output.must_match /:parent/
      output.must_match /20 runs, 8 assertions, 4 failures, 8 errors, 4 skips/
      4.times do |i|
        output.must_match /:child#{i}a/
      end
    end
  end

  it "should call on_parallel_fork_marshal_failure on failure" do
    t = Time.now
    ENV['NCPU'] = '4'
    ENV['MPF_TEST_CHILD_FAILURE'] = '1'
    output = `#{ENV['RUBY']} -I lib spec/minitest_parallel_fork_example.rb 2>&1`
    ENV.delete('MPF_TEST_CHILD_FAILURE')

    time = (Time.now - t)
    time.must_be :<, 4
    output.must_match /:child-failurea/
    output.must_match /marshal data too short/
  end
end
