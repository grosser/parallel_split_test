name = "parallel_split_test"
require "./lib/#{name}/version"

Gem::Specification.new name, ParallelSplitTest::VERSION do |s|
  s.summary = "Split a big test file into multiple chunks and run them in parallel"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib bin Readme.md`.split("\n")
  s.executables = ["parallel_split_test"]
  s.add_dependency "rspec", ">=3.1.0"
  s.add_dependency "parallel", ">=0.5.13"
  s.license = "MIT"
  s.required_ruby_version = '>= 2.2.0'
end
