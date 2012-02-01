require 'rspec/core/example'

RSpec::Core::Example.class_eval do
  alias :run_without_parallel_split_test :run
  def run(*args, &block)
    $example_counter += 1
    if ($example_counter - 1) % $process_count == $process_number
      run_without_parallel_split_test(*args, &block)
    end
  end
end