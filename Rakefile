require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :steep do
    unless RUBY_VERSION.start_with?("2")
        unless RUBY_VERSION.start_with?("3.1")
            sh 'steep check'
        end
    end
end

task :default => [:steep, :spec]
