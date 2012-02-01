module ParallelSplitTest
  class << self
    attr_accessor :example_counter, :process_count, :process_number
  end

  def self.run_example?
    self.example_counter += 1
    (example_counter - 1) % process_count == process_number
  end
end
