gem 'minitest'
require 'minitest/autorun'
require 'minitest/parallel_fork'

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
  end
end
