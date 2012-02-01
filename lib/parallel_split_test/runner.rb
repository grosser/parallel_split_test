require 'rspec/core/runner'
require 'rspec/core/configuration_options'
require 'parallel_split_test/command_line'

# a cleaned up version of the RSpec runner, e.g. no drb support
module ParallelSplitTest
  class Runner < RSpec::Core::Runner
    def self.run(args, err=$stderr, out=$stdout)
      trap_interrupt
      options = RSpec::Core::ConfigurationOptions.new(args)
      options.parse_options
      ParallelSplitTest::CommandLine.new(options).run(err, out)
    ensure
      RSpec.reset
    end
  end
end