gem 'minitest'
require 'minitest/autorun'
require 'minitest/parallel_fork'

if ENV['MPF_TEST_MINITEST_REPORTERS']
  require "minitest/reporters"
  # The minitest-reporters delegate code is activated as soon as it's required
  #  Actually, it's activated as soon as minitest is loaded because of minitest's
  #  plugin autoloading, but that's not our fault
end

a = nil
Minitest.before_parallel_fork do
  a = 'a'
  print ":parent"
end
Minitest.after_parallel_fork do |i|
  print ":child#{i}#{a}"
end

4.times do |i|
  describe 'minitest/parallel_fork' do
    parallelize_me! if ENV['MPF_PARALLELIZE_ME']

    if ENV['MPF_TEST_ORDER_PARALLEL']
      def self.test_order
        :parallel
      end
    end

    it "should work" do
      sleep(1).must_equal 1
    end

    it "should fail" do
      1.must_equal 2
    end

    it "should raise" do
      raise
    end

    it "should skip" do
      skip
    end
  end
end
