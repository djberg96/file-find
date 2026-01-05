# frozen_string_literal: true

######################################################################
# file_find_spec.rb
#
# Test case for the file-find library. You should run this via the
# 'rake spec' task.
######################################################################
require 'rspec'
require 'file-find'
require 'sys-admin'
require 'sys-uname'
require 'tmpdir'
require 'pp' # Goofy workaround for FakeFS bug
require 'fakefs/spec_helpers'

RSpec.describe File::Find do
  include FakeFS::SpecHelpers

  let(:windows)   { Sys::Platform.windows? }
  let(:macos)     { Sys::Platform.mac? }
  let(:elevated)  { windows and Win32::Security.elevated_security? }
  let(:ruby_file) { 'file_find_test.rb' }
  let(:doc_file)  { 'file_find_test.doc' }

  let(:rule) { described_class.new }
  let(:txt_rule) { described_class.new(:name => '*.txt') }

  before(:all) do
    @loguser = Sys::Admin.get_user(Sys::Admin.get_login)
    group = Sys::Platform.windows? ? 'Users' : @loguser.gid
    @logroup = Sys::Admin.get_group(group)
  end

  context 'constants', :constants do
    example 'version constant is set to expected value' do
      expect(File::Find::VERSION).to eq('0.5.2')
      expect(File::Find::VERSION).to be_frozen
    end
  end

  context 'path', :path do
    example 'path accessor basic functionality' do
      expect(rule).to respond_to(:path)
      expect(rule).to respond_to(:path=)
    end

    example 'path method returns expected value' do
      expect(rule.path).to eq(Dir.pwd)
    end
  end

  context 'options', :options do
    example 'options accessor basic functionality' do
      expect(rule).to respond_to(:options)
      expect(rule).to respond_to(:options=)
    end

    example 'options method returns expected value' do
      expect(txt_rule.options).to eq({:name => '*.txt'})
    end
  end

  context 'atime', :atime do
    before do
      FileUtils.touch(ruby_file)
    end

    example 'atime accessor basic functionality' do
      expect(rule).to respond_to(:atime)
      expect(rule).to respond_to(:atime=)
    end

    example 'atime method returns expected default value' do
      expect(rule.atime).to be_nil
    end

    example 'find with atime option works as expected' do
      rule1 = described_class.new(:name => '*.rb', :atime => 0)
      rule2 = described_class.new(:name => '*.rb', :atime => 1)

      expect(rule1.find.empty?).to be false
      expect(rule2.find.empty?).to be true
    end
  end

  context 'ctime', :ctime do
    before do
      FileUtils.touch(ruby_file)
    end

    example 'ctime accessor basic functionality' do
      expect(rule).to respond_to(:ctime)
      expect(rule).to respond_to(:ctime=)
    end

    example 'ctime method returns expected default value' do
      expect(rule.ctime).to be_nil
    end

    example 'find with ctime option works as expected' do
      rule1 = described_class.new(:name => '*.rb', :ctime => 0)
      rule2 = described_class.new(:name => '*.rb', :ctime => 1)

      expect(rule1.find.empty?).to be false
      expect(rule2.find.empty?).to be true
    end
  end

  context 'find', :find do
    example 'find method basic functionality' do
      expect(rule).to respond_to(:find)
      expect{ rule.find }.not_to raise_error
    end

    example 'find method returns expected value' do
      expect(rule.find).to be_a(Array)
      expect(rule.find{}).to be_nil
    end
  end

  context 'filetest', :filetest do
    before do
      FileUtils.touch(doc_file, :mode => 0644)
    end

    example 'filetest accessor basic functionality' do
      expect(rule).to respond_to(:filetest)
      expect(rule).to respond_to(:filetest=)
      expect{ rule.filetest }.not_to raise_error
    end

    example 'filetest method returns expected value' do
      expect(rule.filetest).to be_a(Array)
    end

    example 'valid filetest options work as expected' do
      expect{ described_class.new(:readable? => true) }.not_to raise_error
      expect{ described_class.new(:writable? => true) }.not_to raise_error
    end

    example 'find method works with filetest option' do
      rule = described_class.new(:name => '*.doc', :writable? => true)

      expect(rule.find.map{ |f| File.basename(f) }).to eq([doc_file])
      FileUtils.chmod(0444, doc_file)
      expect(rule.find).to eq([])
    end
  end

  context 'mtime', :mtime do
    before do
      FileUtils.touch(ruby_file)
    end

    example 'mtime accessor basic functionality' do
      expect(rule).to respond_to(:mtime)
      expect(rule).to respond_to(:mtime=)
    end

    example 'mtime method returns expected default value' do
      expect(rule.mtime).to be_nil
    end

    example 'find with mtime option works as expected' do
      rule1 = described_class.new(:name => '*.rb', :mtime => 0)
      rule2 = described_class.new(:name => '*.rb', :mtime => 1)

      expect(rule1.find.empty?).to be false
      expect(rule2.find.empty?).to be true
    end
  end

  context 'ftype', :ftype do
    before do
      FileUtils.touch(ruby_file)
    end

    example 'ftype accessor basic functionality' do
      expect(rule).to respond_to(:ftype)
      expect(rule).to respond_to(:ftype=)
    end

    example 'ftype method returns expected default value' do
      expect(rule.ftype).to be_nil
    end

    example 'ftype method works as expected' do
      rule1 = described_class.new(:name => '*.rb', :ftype => 'file')
      rule2 = described_class.new(:name => '*.rb', :ftype => 'characterSpecial')

      expect(rule1.find.empty?).to be false
      expect(rule2.find.empty?).to be true
    end
  end

  context 'group', :group do
    before do
      FileUtils.touch(doc_file)
    end

    example 'group accessor basic functionality' do
      expect(rule).to respond_to(:group)
      expect(rule).to respond_to(:group=)
    end

    example 'group method returns expected default value' do
      expect(rule.group).to be_nil
    end

    # TODO: Update example for Windows
    example 'find with numeric group id works as expected' do
      skip 'group example skipped on MS Windows' if windows
      skip 'group example skipped on Mac in CI' if macos && ENV['CI']

      rule = described_class.new(:name => '*.doc', :group => @loguser.gid)
      expect(rule.find).to eq([File.expand_path(doc_file)])
    end

    # TODO: Update example for Windows
    example 'find with string group id works as expected' do
      skip 'group example skipped on MS Windows' if windows
      skip 'group example skipped on Mac in CI' if macos && ENV['CI']

      rule = described_class.new(:name => '*.doc', :group => @logroup.name)
      expect(rule.find).to eq([File.expand_path(doc_file)])
    end

    example 'find with bogus group returns empty results' do
      skip 'group test skipped on MS Windows' if windows

      rule1 = described_class.new(:name => '*.doc', :group => 'totallybogus')
      rule2 = described_class.new(:name => '*.doc', :group => 99999999)
      expect(rule1.find).to eq([])
      expect(rule2.find).to eq([])
    end
  end

  context 'inum', :inum do
    example 'inum accessor basic functionality' do
      expect(rule).to respond_to(:inum)
      expect(rule).to respond_to(:inum=)
    end

    example 'inum method returns expected default value' do
      expect(rule.inum).to be_nil
    end
  end

  context 'follow', :follow do
    example 'follow accessor basic functionality' do
      expect(rule).to respond_to(:follow)
      expect(rule).to respond_to(:follow=)
    end

    example 'follow method returns expected default value' do
      expect(rule.follow).to be true
    end
  end

  context 'links', :links do
    before do
      FileUtils.touch(ruby_file)
      FileUtils.touch(doc_file)
    end

    example 'links accessor basic functionality' do
      expect(rule).to respond_to(:links)
      expect(rule).to respond_to(:links=)
    end

    example 'links method returns expected default value' do
      expect(rule.links).to be_nil
    end

    example 'links method returns expected result' do
      skip if windows # && !elevated # TODO: Adjust for drive letter.

      rule1 = described_class.new(:name => '*.rb', :links => 2)
      rule2 = described_class.new(:name => '*.doc', :links => 1)

      expect(rule1.find).to eq([])
      expect(rule2.find).to eq([File.expand_path(doc_file)])
    end
  end

  context 'brackets', :brackets do
    let(:file_rule){ described_class.new(:ftype => 'file', :path => ['/bracket']) }
    let(:dir_rule){ described_class.new(:ftype => 'directory', :path => ['/bracket']) }

    before do
      allow(FakeFS::FileSystem).to receive(:find).and_call_original
      allow(FakeFS::FileSystem).to receive(:find).with(anything, 0, false)
    end

    example 'find method works on dirs that contain brackets' do
      skip 'dirs with brackets example skipped on MS Windows' if windows

      # We use absolute paths here because of fakefs, which converts it anyway
      bracket_files = ['/bracket/a[1]/a.foo', '/bracket/a [2] /b.foo', '/bracket/[a] b [c]/d.foo']
      bracket_paths = ['/bracket/a[1]', '/bracket/a [2] ', '/bracket/[a] b [c]', '/bracket/[z] x']

      bracket_paths.each{ |e| FakeFS::FileSystem.add(e) }
      bracket_files.each{ |e| FileUtils.touch(e) }

      file_results = file_rule.find
      dir_results = dir_rule.find

      expect(file_results).to match_array(bracket_files)
      expect(dir_results).to match_array(bracket_paths)
    end
  end

  context 'maxdepth', :maxdepth do
    before do
      FakeFS::FileSystem.add('a1/a2/a3')
      rule.pattern = '*.foo'

      FileUtils.touch('a1/a.foo')
      FileUtils.touch('a1/a2/b.foo')
      FileUtils.touch('a1/a2/c.foo')
      FileUtils.touch('a1/a2/a3/d.foo')
      FileUtils.touch('a1/a2/a3/e.foo')
      FileUtils.touch('a1/a2/a3/f.foo')
    end

    example 'maxdepth_basic' do
      expect(rule).to respond_to(:maxdepth)
      expect(rule).to respond_to(:maxdepth=)
      expect(rule.maxdepth).to be_nil
    end

    example 'find with maxdepth 1 returns expected results' do
      rule.maxdepth = 1
      expect(rule.find).to eq([])
    end

    example 'find with maxdepth 2 returns expected results' do
      rule.maxdepth = 2
      expect(rule.find.map{ |e| File.basename(e) }).to eq(['a.foo'])
    end

    example 'find with maxdepth 3 returns expected results' do
      rule.maxdepth = 3
      expect(rule.find.map{ |e| File.basename(e) }).to contain_exactly('a.foo', 'b.foo', 'c.foo')
    end

    example 'find with nil maxdepth option returns everything' do
      rule.maxdepth = nil
      results = ['a.foo', 'b.foo', 'c.foo', 'd.foo', 'e.foo', 'f.foo']
      expect(rule.find.map{ |e| File.basename(e) }).to match_array(results)
    end

    example 'find with maxdepth 1 returns expected results for directories' do
      rule.pattern = 'a3'
      rule.maxdepth = 1
      expect(rule.find).to eq([])
    end

    example 'find with maxdepth 2 returns expected results for directories' do
      rule.pattern = 'a3'
      rule.maxdepth = 2
      expect(rule.find).to eq([])
    end

    example 'find with maxdepth 3 returns expected results for directories' do
      rule.pattern = 'a3'
      rule.maxdepth = 3
      expect(rule.find.map{ |e| File.basename(e) }).to eq(['a3'])
    end
  end

  context 'mindepth', :mindepth do
    before do
      FakeFS::FileSystem.add('a1/a2/a3')
      rule.pattern = '*.min'

      FileUtils.touch('z.min')
      FileUtils.touch('a1/a.min')
      FileUtils.touch('a1/a2/b.min')
      FileUtils.touch('a1/a2/c.min')
      FileUtils.touch('a1/a2/a3/d.min')
      FileUtils.touch('a1/a2/a3/e.min')
      FileUtils.touch('a1/a2/a3/f.min')
    end

    example 'mindepth accessor basic functionality' do
      expect(rule).to respond_to(:mindepth)
      expect(rule).to respond_to(:mindepth=)
      expect(rule.mindepth).to be_nil
    end

    example 'mindepth method returns expected default value' do
      expect(rule.mindepth).to be_nil
    end

    example 'find with mindepth option returns expected results at depth 0' do
      rule.mindepth = 0
      array = ['a.min', 'b.min', 'c.min', 'd.min', 'e.min', 'f.min', 'z.min']
      expect(rule.find.map{ |e| File.basename(e) }).to match_array(array)
    end

    example 'find with mindepth option returns expected results at depth 1' do
      rule.mindepth = 1
      array = ['a.min', 'b.min', 'c.min', 'd.min', 'e.min', 'f.min', 'z.min']
      expect(rule.find.map{ |e| File.basename(e) }).to match_array(array)
    end

    example 'find with mindepth option returns expected results at depth 2' do
      rule.mindepth = 2
      array = ['a.min', 'b.min', 'c.min', 'd.min', 'e.min', 'f.min']
      expect(rule.find.map{ |e| File.basename(e) }).to match_array(array)
    end

    example 'find with mindepth option returns expected results at depth 3' do
      rule.mindepth = 3
      array = ['b.min', 'c.min', 'd.min', 'e.min', 'f.min']
      expect(rule.find.map{ |e| File.basename(e) }).to match_array(array)
    end

    example 'find with mindepth option returns expected results at depth 4' do
      rule.mindepth = 4
      array = ['d.min', 'e.min', 'f.min']
      expect(rule.find.map{ |e| File.basename(e) }).to match_array(array)
    end

    example 'find with mindepth option returns expected results at depth 5' do
      rule.mindepth = 5
      expect(rule.find.map{ |e| File.basename(e) }).to eq([])
    end

    example 'find with mindepth option returns expected results for directories' do
      rule.pattern = 'a1'
      rule.mindepth = 1

      expect(rule.find.map{ |e| File.basename(e) }).to eq(['a1'])

      rule.mindepth = 2
      expect(rule.find).to eq([])

      rule.mindepth = 3
      expect(rule.find).to eq([])
    end
  end

  context 'mount', :mount do
    example 'mount accessor basic functionality' do
      expect(rule).to respond_to(:mount)
      expect(rule).to respond_to(:mount=)
    end

    example 'mount method returns expected default value' do
      expect(rule.mount).to be_nil
    end
  end

  context 'name', :name do
    example 'name accessor basic functionality' do
      expect(rule).to respond_to(:name)
      expect(rule).to respond_to(:name=)
    end

    example 'name method returns expected default value' do
      expect(txt_rule.name).to eq('*.txt')
    end

    example 'pattern is an alias for name' do
      expect(rule.method(:name)).to eq(rule.method(:pattern))
      expect(rule.method(:name=)).to eq(rule.method(:pattern=))
    end
  end

  context 'perm', :perm do
    let(:text_file1) { 'file_find_test1.txt' }
    let(:text_file2) { 'file_find_test2.txt' }

    before do
      FileUtils.touch(ruby_file)
      FileUtils.touch(text_file1)
      FileUtils.touch(text_file2)
      File.chmod(0464, ruby_file)
      File.chmod(0644, text_file1)
      File.chmod(0644, text_file2)
    end

    example 'perm accessor basic functionality' do
      expect(rule).to respond_to(:perm)
      expect(rule).to respond_to(:perm=)
    end

    example 'perm method returns expected default value' do
      expect(rule.perm).to be_nil
    end

    example 'perm method returns expected results' do
      results = described_class.new(:name => '*test1*', :perm => 0644).find

      expect(results.length).to eq(1)
      expect(File.basename(results.first)).to eq(text_file1)
    end

    example 'perm method works with symbolic permissions' do
      skip 'symbolic perm spec skipped on MS Windows' if windows

      results1 = described_class.new(:name => 'file*', :perm => 'g=rw').find
      results2 = described_class.new(:name => 'file*', :perm => 'u=rw').find

      expect(results1.length).to eq(1)
      expect(results2.length).to eq(2)
      expect(File.basename(results1.first)).to eq(ruby_file)
      expect(results2.map{ |e| File.basename(e) }.sort).to eq([text_file1, text_file2])
    end
  end

  context 'prune', :prune do
    let(:prune_file) { 'file_find_test_prune.txt' }

    before do
      FileUtils.touch(prune_file)
    end

    example 'prune accessor basic functionality' do
      expect(rule).to respond_to(:prune)
      expect(rule).to respond_to(:prune=)
    end

    example 'prune method returns expected default value' do
      expect(rule.prune).to be_nil
    end

    example 'find method with prune option works as expected' do
      rule = described_class.new(:name => '*.txt', :prune => 'foo')
      expect(File.basename(rule.find.first)).to eq(prune_file)
    end
  end

  context 'size', :size do
    example 'size accessor basic functionality' do
      expect(rule).to respond_to(:size)
      expect(rule).to respond_to(:size=)
    end

    example 'size method returns expected default value' do
      expect(rule.size).to be_nil
    end
  end

  context 'user', :user do
    before do
      FileUtils.touch(doc_file)
    end

    example 'user accessor basic functionality' do
      expect(rule).to respond_to(:user)
      expect(rule).to respond_to(:user=)
    end

    example 'user method returns expected default value' do
      expect(rule.user).to be_nil
    end

    example 'user method works with numeric id as expected' do
      skip 'user example skipped on Mac in CI' if macos && ENV['CI']

      if windows && elevated
        uid = @loguser.gid # Windows assigns the group if any member is an admin
      else
        uid = @loguser.uid
      end

      rule = described_class.new(:name => '*.doc', :user => uid)
      expect(rule.find).to eq([File.expand_path(doc_file)])
    end

    example 'user method works with string as expected' do
      skip 'user example skipped on Mac in CI' if macos && ENV['CI']

      skip if windows && elevated
      rule = described_class.new(:name => '*.doc', :user => @loguser.name)
      expect(rule.find).to eq([File.expand_path(doc_file)])
    end

    example 'find method with user option using invalid user returns expected results' do
      rule1 = described_class.new(:name => '*.doc', :user => 'totallybogus')
      rule2 = described_class.new(:name => '*.doc', :user => 99999999)
      expect(rule1.find).to eq([])
      expect(rule2.find).to eq([])
    end
  end

  context 'previous', :previous do
    example 'previous method basic functionality' do
      expect(rule).to respond_to(:previous)
    end
  end

  example 'an error is raised if the path does not exist' do
    expect{ described_class.new(:path => '/bogus/dir').find }.to raise_error(Errno::ENOENT)
  end

  example 'an error is raised if an invalid option is passed' do
    expect{ described_class.new(:bogus => 1) }.to raise_error(ArgumentError)
    expect{ described_class.new(:bogus? => true) }.to raise_error(ArgumentError)
  end

  context 'eloop', :eloop do
    # Have to disable fakefs for this test because of bug: https://github.com/fakefs/fakefs/issues/459
    before do
      FakeFS.deactivate!
    end

    after do
      FakeFS.activate!
    end

    # TODO: Update example for Windows
    example 'eloop handling works as expected' do
      skip 'eloop handling example skipped on MS Windows' if windows

      Dir.chdir(Dir.mktmpdir) do
        File.symlink('eloop0', 'eloop1')
        File.symlink('eloop1', 'eloop0')
        expected = ['./eloop0', './eloop1']

        results = described_class.new(:path => '.', :follow => true).find
        expect(results.sort).to eq(expected)
      end
    end
  end
end
