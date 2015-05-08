require 'minitest/autorun'

describe 'minitest/parallel_fork' do
  it "should work" do
    t = Time.now
    ENV['NCPU'] = '4'
    output = `#{ENV['RUBY']} -I lib spec/minitest_parallel_fork_example.rb`
    (Time.now - t).must_be :<, 4
    output.must_match /:parent/
    4.times do |i|
      output.must_match /:child#{i}a/
    end
  end
end
