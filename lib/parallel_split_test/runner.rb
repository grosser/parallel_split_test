require 'parallel_split_test/command_line'
require 'shellwords'

# a cleaned up version of the RSpec runner, e.g. no drb support
module ParallelSplitTest
  class Runner < RSpec::Core::Runner
    # @overwrite
    # stripped down version of run without --drb support / option parsing
    def self.run(args, err=$stderr, out=$stdout)
      trap_interrupt

      report_execution_time(out) do
        ParallelSplitTest::CommandLine.new(args).run(err, out)
      end
    ensure
      RSpec.reset
    end

    private

    def self.report_execution_time(out)
      start = Time.now.to_f
      result = yield
      runtime = Time.now.to_f - start
      out.puts "Took %.2f seconds with #{ParallelSplitTest.processes} processes" % runtime
      result
    end
  end
end
