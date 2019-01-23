require 'rubygems'

Gem::Specification.new do |spec|
  spec.name       = 'file-find'
  spec.version    = '0.4.0'
  spec.author     = 'Daniel Berger'
  spec.license    = 'Apache-2.0'
  spec.summary    = 'A better way to find files'
  spec.email      = 'djberg96@gmail.com'
  spec.homepage   = 'http://github.com/djberg96/file-find'
  spec.test_file  = 'test/test_file_find.rb'
  spec.files      = Dir['**/*'].reject{ |f| f.include?('git') }
  spec.cert_chain = Dir['certs/*']

  spec.extra_rdoc_files  = ['README', 'CHANGES', 'MANIFEST']

  spec.metadata = {
    'homepage_uri'      => 'https://github.com/djberg96/file-find',
    'bug_tracker_uri'   => 'https://github.com/djberg96/file-find/issues',
    'changelog_uri'     => 'https://github.com/djberg96/file-find/blob/master/CHANGES',
    'documentation_uri' => 'https://github.com/djberg96/file-find/wiki',
    'source_code_uri'   => 'https://github.com/djberg96/file-find',
    'wiki_uri'          => 'https://github.com/djberg96/file-find/wiki'
  }

  spec.add_dependency('sys-admin', '>= 1.6.0')
  spec.add_development_dependency('test-unit')
  spec.add_development_dependency('rake')

  spec.description = <<-EOF
    The file-find library provides a better, more object oriented approach
    to finding files. It allows you to find files based on a variety of
    properties, such as access time, size, owner, etc. You can also limit
    directory depth.
  EOF
end
