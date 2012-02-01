require 'parallel'
require 'rspec/core/command_line'
require 'parallel_split_test/core_ext/rspec_example'

module ParallelSplitTest
  class CommandLine < RSpec::Core::CommandLine
    def run(err, out)
      setup_copied_from_rspec(err, out)
      processes = (ENV['PARALLEL_SPLIT_TEST_PROCESSES'] || Parallel.processor_count).to_i

      Parallel.in_processes(processes) do |process_number|
        $example_counter = 0
        $process_count = processes
        $process_number = process_number

        ENV['TEST_ENV_NUMBER'] = (process_number == 0 ? '' : (process_number + 1).to_s)
        run_group_of_tests(processes, process_number)
      end
    end

    private

    def run_group_of_tests(processes, process_number)
      example_count = @world.example_count / processes

      @configuration.reporter.report(example_count, seed) do |reporter|
        begin
          @configuration.run_hook(:before, :suite)
          groups = @world.example_groups.ordered
          groups.map {|g| g.run(reporter)}.all? ? 0 : @configuration.failure_exit_code
        ensure
          @configuration.run_hook(:after, :suite)
        end
      end
    end

    def seed
      @configuration.randomize? ? @configuration.seed : nil
    end

    def setup_copied_from_rspec(err, out)
      @configuration.error_stream = err
      @configuration.output_stream ||= out
      @options.configure(@configuration)
      @configuration.load_spec_files
      @world.announce_filters
    end
  end
end