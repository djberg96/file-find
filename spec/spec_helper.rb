require 'rspec'
require 'file-find'
require 'sys-admin'
require 'tmpdir'
require 'memfs'

RSpec.configure do |c|
  c.around(:each, memfs: true) do |example|
    MemFs.activate { example.run }
  end
end
