$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
name = "parallel_split_test"
require "#{name}/version"

Gem::Specification.new name, ParallelSplitTest::VERSION do |s|
  s.summary = "Split a big test file into multiple chunks and run them in parallel"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/#{name}"
  s.files = `git ls-files`.split("\n")
  s.executables = ["parallel_split_test"]
  s.add_dependency "rspec", ">=2"
  s.add_dependency "parallel", ">=0.5.12"
  s.license = "MIT"
end
