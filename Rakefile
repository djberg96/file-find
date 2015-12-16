require 'rake'
require 'rake/clean'
require 'rake/testtask'

CLEAN.include("**/*.gem", "**/*.rbc", "**/link*")

namespace :gem do
  desc 'Create the file-find gem'
  task :create => [:clean] do
    require 'rubygems/package'
    spec = eval(IO.read('file-find.gemspec'))
    spec.signing_key = File.join(Dir.home, '.ssh', 'gem-private_key.pem')
    Gem::Package.build(spec, true)
  end

  desc "Install the file-find gem"
  task :install => [:create] do
    ruby 'file-find.gemspec'
    file = Dir["*.gem"].first
    sh "gem install -l #{file}"
  end
end

Rake::TestTask.new do |t|
  task :test => 'clean'
  t.warning = true
  t.verbose = true
end

task :default => :test
