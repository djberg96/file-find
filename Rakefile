require 'rake'
require 'rake/clean'
require 'rake/testtask'

CLEAN.include("**/*.gem", "**/*.rbc", "**/link*")

namespace :gem do
  desc 'Create the file-find gem'
  task :create => [:clean] do
    spec = eval(IO.read('file-find.gemspec'))
    if Gem::VERSION.to_f < 2.0
      Gem::Builder.new(spec).build
    else
      require 'rubygems/package'
      Gem::Package.build(spec)
    end
  end

  desc "Install the file-find gem"
  task :install => [:create] do
    ruby 'file-find.gemspec'
    file = Dir["*.gem"].first
    sh "gem install #{file}"
  end
end

Rake::TestTask.new do |t|
  task :test => 'clean'
  t.warning = true
  t.verbose = true
end

task :default => :test
