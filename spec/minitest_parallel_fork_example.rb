gem 'minitest'
require 'minitest/global_expectations/autorun'
require 'minitest/parallel_fork'
require 'minitest/hooks/default' if ENV['MPF_MINITEST_HOOKS']


a = nil
if ENV['MPF_NO_HOOKS']
  a = 'a'
else
  Minitest.before_parallel_fork do
    a = 'a'
    print ":parent"
  end

  Minitest.after_parallel_fork do |i|
    print ":child#{i}#{a}"
  end

  if ENV['MPF_TEST_CHILD_FAILURE']
    Minitest.on_parallel_fork_marshal_failure do |i|
      print ":child-failure#{i}#{a}"
    end
  end
end

class MyExceptionClass < StandardError
  attr_accessor :something
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
      sleep(1)
      1.must_equal 1
    end

    it "should fail" do
      1.must_equal 2
    end

    it "should raise" do
      exit(1) if ENV['MPF_TEST_CHILD_FAILURE']
      raise
    end

    it "should raise exception containing undumpable data" do
      e = MyExceptionClass.new("error")
      e.something = Class.new
      raise e
    end

    it "should skip" do
      skip
    end
  end
end

if ENV['MPF_MINITEST_HOOKS']
  describe "failure in before(:all)" do
    before(:all) do
      e = MyExceptionClass.new("error")
      e.something = Class.new
      raise e
    end
    it "should fail" do end
  end

  describe "failure in after(:all)" do
    after(:all) do
      e = MyExceptionClass.new("error")
      e.something = Class.new
      raise e
    end
    it "should fail" do end
  end
end
