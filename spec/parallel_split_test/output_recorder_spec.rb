require "spec_helper"

describe ParallelSplitTest::OutputRecorder do
  ['write', 'puts', 'print'].each do |method|
    it "records #{method}" do
      out = StringIO.new("")
      recorder = ParallelSplitTest::OutputRecorder.new(out)
      recorder.send(method, "XXX")

      # output got recorded
      recorder.recorded.strip.should == "XXX"
      out.read.should == ""

      # output was written to original
      out.rewind
      out.read.strip.should == "XXX"
    end
  end

  it "can puts without arguments" do
    out = StringIO.new("")
    recorder = ParallelSplitTest::OutputRecorder.new(out)
    recorder.puts
    recorder.recorded.should == "\n"
  end
end