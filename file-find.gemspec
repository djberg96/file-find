require 'rubygems'

Gem::Specification.new do |spec|
  spec.name       = 'file-find'
  spec.version    = '0.5.2'
  spec.author     = 'Daniel Berger'
  spec.license    = 'Apache-2.0'
  spec.summary    = 'A better way to find files'
  spec.email      = 'djberg96@gmail.com'
  spec.homepage   = 'http://github.com/djberg96/file-find'
  spec.test_file  = 'spec/file_find_spec.rb'
  spec.files      = Dir['**/*'].reject{ |f| f.include?('git') }
  spec.cert_chain = Dir['certs/*']

  spec.metadata = {
    'homepage_uri'          => 'https://github.com/djberg96/file-find',
    'bug_tracker_uri'       => 'https://github.com/djberg96/file-find/issues',
    'changelog_uri'         => 'https://github.com/djberg96/file-find/blob/main/CHANGES.md',
    'documentation_uri'     => 'https://github.com/djberg96/file-find/wiki',
    'source_code_uri'       => 'https://github.com/djberg96/file-find',
    'wiki_uri'              => 'https://github.com/djberg96/file-find/wiki',
    'rubygems_mfa_required' => 'true',
    'github_repo'           => 'https://github.com/djberg96/file-find',
    'funding_uri'           => 'https://github.com/sponsors/djberg96'
  }

  spec.add_dependency('sys-admin', '~> 1.7')

  if Gem.win_platform?
    spec.add_dependency('win32ole')
    spec.add_dependency('win32-registry') # Until sys-admin gets updated properly
  end

  spec.add_development_dependency('rspec', '~> 3.9')
  spec.add_development_dependency('fakefs', '~> 3.0')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rubocop')
  spec.add_development_dependency('rubocop-rspec')
  spec.add_development_dependency('sys-uname')

  spec.description = <<-EOF
    The file-find library provides a better, more object oriented approach
    to finding files. It allows you to find files based on a variety of
    properties, such as access time, size, owner, etc. You can also limit
    directory depth.
  EOF
end
