require 'stringio'

module ParallelSplitTest
  class OutputRecorder
    def initialize(out)
      @recorded = StringIO.new
      @out = out
    end

    %w[puts write print putc flush tty? closed?].each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__
        def #{method}(*args)
          @recorded.#{method}(*args)
          @out.#{method}(*args)
        end
      RUBY
    end

    def recorded
      @recorded.rewind
      @recorded.read
    end
  end
end
