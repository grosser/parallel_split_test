require "spec_helper"

describe ParallelSplitTest::OutputRecorder do
  ['write', 'puts', 'print'].each do |method|
    it "records #{method}" do
      out = StringIO.new("")
      recorder = ParallelSplitTest::OutputRecorder.new(out)
      recorder.send(method, "XXX")

      # output got recorded
      expect(recorder.recorded.strip).to eq("XXX")
      expect(out.read).to eq("")

      # output was written to original
      out.rewind
      expect(out.read.strip).to eq("XXX")
    end
  end

  it "can puts without arguments" do
    out = StringIO.new("")
    recorder = ParallelSplitTest::OutputRecorder.new(out)
    recorder.puts
    expect(recorder.recorded).to eq("\n")
  end
end
