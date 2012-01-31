require 'spec_helper'

describe ParallelSplitTest do
  it "has a VERSION" do
    ParallelSplitTest::VERSION.should =~ /^[\.\da-z]+$/
  end
end
