require 'bundler/setup'

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

require 'coveralls/rake/task'
Coveralls::RakeTask.new
task :test_with_coveralls => [:spec, :features, 'coveralls:push']

task :default => :test_with_coveralls

require 'yard'
YARD::Rake::YardocTask.new
