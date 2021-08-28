require 'parallel'

module ParallelSplitTest
  class << self
    attr_accessor :example_counter, :processes, :process_number

    def run_example?
      self.example_counter += 1
      (example_counter - 1) % processes == process_number
    end

    def choose_number_of_processes
      self.processes = best_number_of_processes
    end

    def best_number_of_processes
      Integer(ENV['PARALLEL_SPLIT_TEST_PROCESSES'] || Parallel.processor_count)
    end
  end
end
