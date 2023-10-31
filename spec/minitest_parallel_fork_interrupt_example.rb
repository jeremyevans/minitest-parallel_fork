gem 'minitest'
require 'minitest/global_expectations/autorun'
require 'minitest/parallel_fork'
require 'minitest/unit'
require 'minitest/hooks/default' if ENV['MPF_MINITEST_HOOKS']

ENV['NCPU'] = '4'

# Taken and adapted from [Minitest.load_plugin](https://github.com/minitest/minitest/blob/6719ad8d8d49779669083f5029ea9a0429c49ff5/lib/minitest.rb#L108)
#
# We want to load plugins in spce/plugins and not in this Gem's lib/minitest
# because:
#
#   1. the plugin doesn't belong to the library.
#   2. the plugin doesn't behave as a proper plugin:
#     a. we don't parse arguments and just load it
#     b. we print to stdout and later on check the output for un/desired output
module Minitest
  def self.load_mpf_plugins
    return unless self.extensions.empty?

    seen = {}

    Dir['spec/plugins/*_plugin.rb'].each do |plugin_path|
      name = File.basename plugin_path, '_plugin.rb'

      next if seen[name]
      seen[name] = true

      require_relative plugin_path.gsub(/\Aspec\//, '')
      self.extensions << name
    end
  end
end

Minitest.load_mpf_plugins

if ENV['MPF_FAIL_FAST']
  class MyTest < MiniTest::Test
    describe "failure through Interrupt" do
      # We need to order the tests in order to verify the correct handling of
      # the raised Interrupt by `Minitest.__run`.
      # Unordered execution does not guarantee the number of un/executed tests,
      # and assersions in `minitest_parallel_fork_spec.rb` would be impossible.
      i_suck_and_my_tests_are_order_dependent!

      parallelize_me! if ENV['MPF_PARALLELIZE_ME']

      it "should fail" do
        1.must_equal 2
      end

      it "should pass but will not" do
        # We need to run a costly computation and not a `sleep`!
        # Sleeping would not allow the runners to intercept the Interrupt or
        # USR1 signals, and therefore we cannot reliably test for proper test
        # abortion.
        (1..1000000).inject(:*)
        puts 'before must_equal'
        1.must_equal 1
        puts 'after must_equal'
      end
    end
  end
end
