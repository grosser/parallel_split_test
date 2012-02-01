require 'parallel_split_test'
require 'rspec/core/example'

RSpec::Core::Example.class_eval do
  alias :run_without_parallel_split_test :run
  def run(*args, &block)
    if ParallelSplitTest.run_example?
      run_without_parallel_split_test(*args, &block)
    end
  end
end