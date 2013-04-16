require 'bundler/setup'
require 'bundler/gem_tasks'
require 'bump/tasks'

task :default do
  sh "rspec spec/"
end

task :selftest do
  sh "./bin/parallel_split_test spec/"
end
