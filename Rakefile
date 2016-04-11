# encoding: UTF-8
require 'rubygems'

require 'bundler'
require 'bundler/setup'
require 'bundler/gem_tasks'

require 'cucumber/rake/task'
require 'rspec/core/rake_task'
require 'coveralls/rake/task'

require 'yard'

begin
  Bundler.setup(:default, :development, :test)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end

RSpec::Core::RakeTask.new(:examples) do |examples|
  examples.rspec_opts = '-Ispec'
end

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = '-Ispec'
  spec.rcov = true
end

Cucumber::Rake::Task.new(:features)

Coveralls::RakeTask.new

YARD::Rake::YardocTask.new

task test_with_coveralls: [:features, 'coveralls:push']

task default: :test_with_coveralls
