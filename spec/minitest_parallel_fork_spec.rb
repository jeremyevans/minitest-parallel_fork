gem 'minitest'
require 'minitest/autorun'

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
      4.times do |i|
        output.must_match /:child#{i}a/
      end
    end
  end
end
