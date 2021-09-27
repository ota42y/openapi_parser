require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :steep do
sh 'steep check'
end

task :default => [:steep, :spec]
