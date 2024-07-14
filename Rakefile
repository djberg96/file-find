require 'rake'
require 'rake/clean'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

CLEAN.include("**/*.gem", "**/*.rbc", "**/link*", "*.lock")

namespace :gem do
  desc 'Create the file-find gem'
  task :create => [:clean] do
    require 'rubygems/package'
    spec = Gem::Specification.load('file-find.gemspec')
    spec.signing_key = File.join(Dir.home, '.ssh', 'gem-private_key.pem')
    Gem::Package.build(spec)
  end

  desc "Install the file-find gem"
  task :install => [:create] do
    ruby 'file-find.gemspec'
    file = Dir["*.gem"].first
    sh "gem install -l #{file}"
  end
end

RuboCop::RakeTask.new

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = ['spec/file_find_spec.rb']
end

# Clean up afterwards
Rake::Task[:spec].enhance do
  Rake::Task[:clean].invoke
end

task :default => :spec
