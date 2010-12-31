require 'rake'
require 'rake/clean'
require 'rake/testtask'

CLEAN.include("**/*.gem", "**/*.rbc")

namespace :gem do
  desc 'Create the file-find gem'
  task :create => [:clean] do
    spec = eval(IO.read('file-find.gemspec'))
    if RUBY_PLATFORM.match('java')
      spec.platform = Gem::Platform::CURRENT
    else
      spec.add_dependency('sys-admin', '>= 1.5.2')
    end   

    Gem::Builder.new(spec).build
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
