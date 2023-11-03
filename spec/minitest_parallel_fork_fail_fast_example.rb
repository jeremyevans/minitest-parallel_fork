require 'minitest/global_expectations/autorun'
require 'minitest/parallel_fork/fail_fast'

lock_file = "spec/spec-wait-#{$$}.lock"
File.write(lock_file, "") 

suites = Minitest::Runnable.runnables
suites.delete(Minitest::Test)
suites.delete(Minitest::Spec)

# Force in-order execution of test suites
def suites.shuffle; self end

4.times do |i|
  describe "test suite with fail_fast" do
    Object.send(:const_set, :"FailingTest#{i}", self)
    if i == 0
      it "should fail" do
        # Wait until 3 other forks are in first spec
        sleep(0.01) while File.size(lock_file) < 3

        1.must_equal 2
      end
    else
      it "wait until other child failed, then pass" do
        # Mark this fork has reached this spec
        File.open(lock_file, 'ab'){|f| f << i.to_s}

        # Wait until one fork has a failed and the
        # parent process has signaled the child processes
        sleep(0.01) while File.file?(lock_file)

        1.must_equal 1
        2.must_equal 2
      end
    end
  end
end

4.times do |i|
  describe "will not be executed with fail_fast" do
    Object.send(:const_set, :"PassingTest#{i}", self)
    it "will not be executed" do
      puts "not_executed"
      1.must_equal 1
    end
  end
end

Thread.new do
  Minitest.module_eval do
    sleep 0.01 until @parallel_fork_stop == :FINISHED

    # Delete the lock file after signaling child processes
    File.delete(lock_file)
  end
end
