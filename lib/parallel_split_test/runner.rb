require 'parallel_split_test/command_line'

# a cleaned up version of the RSpec runner, e.g. no drb support
module ParallelSplitTest
  class Runner < RSpec::Core::Runner
    def self.run(args, err=$stderr, out=$stdout)
      trap_interrupt
      options = RSpec::Core::ConfigurationOptions.new(args)
      options.parse_options

      ParallelSplitTest.choose_number_of_processes
      out.puts "Running examples in #{ParallelSplitTest.processes} processes"

      report_execution_time(out) do
        results = ParallelSplitTest::CommandLine.new(options).run(err, out)
        reprint_result_lines(out, results.map(&:last))
        results.map(&:first).max
      end
    ensure
      RSpec.reset
    end

    def self.report_execution_time(out)
      start = Time.now.to_f
      result = yield
      runtime = Time.now.to_f - start
      out.puts "Took %.2f seconds with #{ParallelSplitTest.processes} processes" % runtime
      result
    end

    def self.reprint_result_lines(out, printed_outputs)
      out.puts
      out.puts "Summary:"
      out.puts printed_outputs.map{|o| o[/.*\d+ failure.*/] }.join("\n")
    end
  end
end