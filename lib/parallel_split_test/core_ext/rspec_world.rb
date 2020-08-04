require 'parallel_split_test'
require 'rspec/core/example'

RSpec::Core::World.class_eval do
  alias :original_prepare_example_filtereing :prepare_example_filtering

  def prepare_example_filtering
    @original_filtered_examples = original_prepare_example_filtereing
    @filtered_examples = Hash.new do |hash, group|
      hash[group] = @original_filtered_examples[group].select do |x|
        ParallelSplitTest.run_example?
      end
    end
  end
end
