require 'parallel_split_test'
require 'parallel'
require 'rspec'
require 'parallel_split_test/core_ext/rspec_example'

module ParallelSplitTest
  class CommandLine < RSpec::Core::CommandLine
    def run(err, out)
      ParallelSplitTest.choose_number_of_processes

      Parallel.in_processes(ParallelSplitTest.processes) do |process_number|
        ENV['TEST_ENV_NUMBER'] = (process_number == 0 ? '' : (process_number + 1).to_s)
        setup_copied_from_rspec(err, out)

        ParallelSplitTest.example_counter = 0
        ParallelSplitTest.process_number = process_number

        run_group_of_tests
      end
    end

    private

    def run_group_of_tests
      example_count = @world.example_count / ParallelSplitTest.processes

      @configuration.reporter.report(example_count, seed) do |reporter|
        begin
          @configuration.run_hook(:before, :suite)
          groups = @world.example_groups.ordered
          results = groups.map {|g| g.run(reporter)}
          results.all? ? 0 : @configuration.failure_exit_code
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