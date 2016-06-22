require 'parallel_split_test'
require 'parallel_split_test/output_recorder'
require 'parallel'
require 'rspec'
require 'parallel_split_test/core_ext/rspec_example'

module ParallelSplitTest
  class CommandLine < RSpec::Core::Runner
    def initialize(args)
      @args = args
      super
    end

    def run(err, out)
      no_summary = @args.delete('--no-summary')
      no_merge = @args.delete('--no-merge')

      @options = RSpec::Core::ConfigurationOptions.new(@args)

      processes = ParallelSplitTest.choose_number_of_processes
      out.puts "Running examples in #{processes} processes"

      results = Parallel.in_processes(processes) do |process_number|
        ParallelSplitTest.example_counter = 0
        ParallelSplitTest.process_number = process_number
        set_test_env_number(process_number)
        modify_out_file_in_args(process_number) if out_file
        out = OutputRecorder.new(out)
        setup_copied_from_rspec(err, out)
        [run_group_of_tests, out.recorded]
      end


      combine_out_files if out_file unless no_merge

      reprint_result_lines(out, results.map(&:last)) unless no_summary
      results.map(&:first).max # combine exit status
    end

    private

    # modify + reparse args to unify output
    def modify_out_file_in_args(process_number)
      target = out_file.split(".")
      target[target.length - 2] = target[target.length - 2] << "." << process_number.to_s
      @args[out_file_position] = target.join(".")
      @options = RSpec::Core::ConfigurationOptions.new(@args)
    end

    def set_test_env_number(process_number)
      ENV['TEST_ENV_NUMBER'] = (process_number == 0 ? '' : (process_number + 1).to_s)
    end

    def out_file
      @out_file ||= @args[out_file_position] if out_file_position
    end

    def out_file_position
      @out_file_position ||= begin
        if out_position = @args.index { |i| ["-o", "--out"].include?(i) }
          out_position + 1
        end
      end
    end

    def combine_out_files
      File.open(out_file, "w") do |f|
        target = out_file.split(".")
        target[target.length - 2] = target[target.length - 2] << ".*"
        Dir["#{target.join(".")}"].each do |file|
          f.write File.read(file)
          File.delete(file)
        end
      end
    end

    def reprint_result_lines(out, printed_outputs)
      out.puts
      out.puts "Summary:"
      out.puts printed_outputs.map{|o| o[/.*\d+ failure.*/] }.join("\n")
    end

    def run_group_of_tests
      example_count = @world.example_count / ParallelSplitTest.processes

      @configuration.reporter.report(example_count) do |reporter|
        groups = @world.example_groups
        results = groups.map {|g| g.run(reporter)}
        results.all? ? 0 : @configuration.failure_exit_code
      end
    end

    # https://github.com/rspec/rspec-core/blob/6ee92a0d47bcb1f3abcd063dca2cee005356d709/lib/rspec/core/runner.rb#L93
    def setup_copied_from_rspec(err, out)
      @configuration.error_stream = err
      @configuration.output_stream = out if @configuration.output_stream == $stdout
      @options.configure(@configuration)
      @configuration.load_spec_files
      @world.announce_filters
    end
  end
end
