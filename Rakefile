require 'bundler/setup'

require 'bueller'
Bueller::Tasks.new
Bueller::GemcutterTasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:examples) do |examples|
  examples.rspec_opts = '-Ispec'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.rspec_opts = '-Ispec'
  spec.rcov = true
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features)

task :default => :examples

require 'yard'
YARD::Rake::YardocTask.new
