require 'parallel_split_test'
require 'rspec/core/example'

RSpec::Core::World.class_eval do
  alias :example_count_without_parallel_split_test :example_count
  def example_count(*args, &block)
    count = example_count_without_parallel_split_test(*args, &block)
    quotient = count / ParallelSplitTest.processes
    if ParallelSplitTest.process_number < count % ParallelSplitTest.processes
      quotient + 1
    else
      quotient
    end
  end
end
