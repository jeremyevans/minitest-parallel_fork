require 'minitest/global_expectations/autorun'
require 'minitest/parallel_fork/interrupt'

4.times do |i|
  describe "test suite with interrupt - #{i}" do
    it "should wait" do
      sleep(1) while true
    end
  end
end
