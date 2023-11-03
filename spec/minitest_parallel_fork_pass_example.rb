require 'minitest/global_expectations/autorun'
require 'minitest/hooks/default' if ENV['MPF_MINITEST_HOOKS']

if ENV['MPF_FAIL_FAST']
  require 'minitest/parallel_fork/fail_fast'
else
  require 'minitest/parallel_fork'
end

8.times do |i|
  describe "test suite #{i}" do
    parallelize_me! if ENV['MPF_PARALLELIZE_ME']

    if ENV['MPF_TEST_ORDER_PARALLEL']
      def self.test_order
        :parallel
      end
    end

    4.times do |j|
      it "spec #{i}-#{j}" do
        1.must_equal 1
        2.must_equal 2
      end
    end

    it "skip-#{i}" do
      skip
    end
  end
end
