require 'parallel'
require 'rspec/core/command_line'

module ParallelSplitTest
  class CommandLine < RSpec::Core::CommandLine
    def run(err, out)
      setup_copied_from_rspec(err, out)

      processes = Parallel.processor_count
      example_count = @world.example_count / processes
      seed = (@configuration.randomize? ? @configuration.seed : nil)

      Parallel.in_processes(processes) do |process_number|
        ENV['TEST_ENV_NUMBER'] = (process_number == 0 ? '' : (process_number + 1).to_s)

        @configuration.reporter.report(example_count, seed) do |reporter|
          begin
            @configuration.run_hook(:before, :suite)
            groups = groups_for_this_process(@world.example_groups.ordered, process_number, processes)
            puts "PROCESS #{process_number} -- #{groups.size}"

            groups.map {|g| g.run(reporter)}.all? ? 0 : @configuration.failure_exit_code
          ensure
            @configuration.run_hook(:after, :suite)
          end
        end
      end
    end

    private

    def groups_for_this_process(groups, number, count)
      selected = []
      groups.each_with_index do |group, i|
        selected << group if i % count == number
      end
      selected
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