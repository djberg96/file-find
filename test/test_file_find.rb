######################################################################
# test_file_find.rb
#
# Test case for the File::Find package. You should run this via the
# 'rake test' task.
######################################################################
require 'test-unit'
require 'fileutils'
require 'file/find'
require 'sys/admin'

if File::ALT_SEPARATOR
  require 'win32/file'
  require 'win32/security'
end

include FileUtils

class TC_File_Find < Test::Unit::TestCase
  def self.startup
    Dir.chdir(File.dirname(File.expand_path(__FILE__)))

    @@windows = File::ALT_SEPARATOR
    @@jruby   = RUBY_PLATFORM.match('java')

    if @@windows
      @@elevated = Win32::Security.elevated_security?
      if @@elevated
        @@loguser = Sys::Admin.get_group("Administrators", :LocalAccount => true)
      else
        @@loguser = Sys::Admin.get_user(Sys::Admin.get_login, :LocalAccount => true)
      end
    else
      @@loguser = Sys::Admin.get_user(Sys::Admin.get_login)
      @@logroup = Sys::Admin.get_group(@@loguser.gid)
    end
  end

  def setup
    @file_rb    = 'test1.rb'
    @file_txt1  = 'test1.txt'
    @file_txt2  = 'foo.txt'
    @file_doc   = 'foo.doc'
    @directory1 = 'dir1'
    @directory2 = 'dir2'

    File.open(@file_rb, 'w'){}
    File.open(@file_txt1, 'w'){}
    File.open(@file_txt2, 'w'){}
    File.open(@file_doc, 'w'){}

    @link1 = 'link1'

    if @@windows
      File.symlink(@file_rb, @link1) if @@elevated
    else
      File.symlink(@file_rb, @link1)
    end

    Dir.mkdir(@directory1) unless File.exist?(@directory1)
    Dir.mkdir(@directory2) unless File.exist?(@directory2)

    File.open(File.join(@directory1, 'bar.txt'), 'w'){}
    File.open(File.join(@directory2, 'baz.txt'), 'w'){}

    @rule1 = File::Find.new(:name => '*.txt')
    @rule2 = File::Find.new
  end

  test "version constant is set to expected value" do
    assert_equal('0.3.9', File::Find::VERSION)
  end

  test "path accessor basic functionality" do
    assert_respond_to(@rule1, :path)
    assert_respond_to(@rule1, :path=)
  end

  test "path method returns expected value" do
    assert_equal(Dir.pwd, @rule1.path)
  end

  test "options accessor basic functionality" do
    assert_respond_to(@rule1, :options)
    assert_respond_to(@rule1, :options=)
  end

  test "options method returns expected value" do
    assert_equal({:name => '*.txt'}, @rule1.options)
  end

  test "atime accessor basic functionality" do
    assert_respond_to(@rule1, :atime)
    assert_respond_to(@rule1, :atime=)
  end

  test "atime method returns expected default value" do
    assert_nil(@rule1.atime)
  end

  test "find with atime option works as expected" do
    rule1 = File::Find.new(:name => "*.rb", :atime => 0)
    rule2 = File::Find.new(:name => "*.rb", :atime => 1)

    assert_false(rule1.find.empty?)
    assert_true(rule2.find.empty?)
  end

  test "ctime accessor basic functionality" do
    assert_respond_to(@rule1, :ctime)
    assert_respond_to(@rule1, :ctime=)
  end

  test "ctime method returns expected default value" do
    assert_nil(@rule1.ctime)
  end

  test "find with ctime option works as expected" do
    rule1 = File::Find.new(:name => "*.rb", :ctime => 0)
    rule2 = File::Find.new(:name => "*.rb", :ctime => 1)

    assert_false(rule1.find.empty?)
    assert_true(rule2.find.empty?)
  end

  test "find method basic functionality" do
    assert_respond_to(@rule1, :find)
    assert_nothing_raised{ @rule1.find }
  end

  test "find method returns expected value" do
    assert_kind_of(Array, @rule1.find)
    assert_nil(@rule1.find{})
  end

  test "filetest accessor basic functionality" do
    assert_respond_to(@rule1, :filetest)
    assert_respond_to(@rule1, :filetest=)
    assert_nothing_raised{ @rule1.filetest }
  end

  test "filetest method returns expected value" do
    assert_kind_of(Array, @rule1.filetest)
  end

  test "valid filetest options work as expected" do
    assert_nothing_raised{ File::Find.new(:readable? => true) }
    assert_nothing_raised{ File::Find.new(:writable? => true) }
  end

  test "find method works with filetest option" do
    rule = File::Find.new(:name => "*.doc", :writable? => true)
    File.chmod(0644, @file_doc)

    assert_equal([@file_doc], rule.find.map{ |f| File.basename(f) })

    File.chmod(0444, @file_doc)

    assert_equal([], rule.find)
  end

  test "mtime accessor basic functionality" do
    assert_respond_to(@rule1, :mtime)
    assert_respond_to(@rule1, :mtime=)
  end

  test "mtime method returns expected default value" do
    assert_nil(@rule1.mtime)
  end

  test "find with mtime option works as expected" do
    rule1 = File::Find.new(:name => "*.rb", :mtime => 0)
    rule2 = File::Find.new(:name => "*.rb", :mtime => 1)

    assert_false(rule1.find.empty?)
    assert_true(rule2.find.empty?)
  end

  test "ftype accessor basic functionality" do
    assert_respond_to(@rule1, :ftype)
    assert_respond_to(@rule1, :ftype=)
  end

  test "ftype method returns expected default value" do
    assert_nil(@rule1.ftype)
  end

  test "ftype method works as expected" do
    rule1 = File::Find.new(:name => "*.rb", :ftype => "file")
    rule2 = File::Find.new(:name => "*.rb", :ftype => "characterSpecial")

    assert_false(rule1.find.empty?)
    assert_true(rule2.find.empty?)
  end

  test "group accessor basic functionality" do
    assert_respond_to(@rule1, :group)
    assert_respond_to(@rule1, :group=)
  end

  test "group method returns expected default value" do
    assert_nil(@rule1.group)
  end

  # TODO: Update test for Windows
  test "find with numeric group id works as expected" do
    omit_if(@@windows, 'group test skipped on MS Windows')
    @rule1 = File::Find.new(:name => '*.doc', :group => @@loguser.gid)
    assert_equal([File.expand_path(@file_doc)], @rule1.find)
  end

  # TODO: Update test for Windows
  test "find with string group id works as expected" do
    omit_if(@@windows, 'group test skipped on MS Windows')
    @rule1 = File::Find.new(:name => '*.doc', :group => @@logroup.name)
    assert_equal([File.expand_path(@file_doc)], @rule1.find)
  end

  test "find with bogus group returns empty results" do
    omit_if(@@windows, 'group test skipped on MS Windows')
    @rule1 = File::Find.new(:name => '*.doc', :group => 'totallybogus')
    @rule2 = File::Find.new(:name => '*.doc', :group => 99999999)
    assert_equal([], @rule1.find)
    assert_equal([], @rule2.find)
  end

  test "inum accessor basic functionality" do
    assert_respond_to(@rule1, :inum)
    assert_respond_to(@rule1, :inum=)
  end

  test "inum method returns expected default value" do
    assert_nil(@rule1.inum)
  end

  test "follow accessor basic functionality" do
    assert_respond_to(@rule1, :follow)
    assert_respond_to(@rule1, :follow=)
  end

  test "follow method returns expected default value" do
    assert_true(@rule1.follow)
  end

  test "links accessor basic functionality" do
    assert_respond_to(@rule1, :links)
    assert_respond_to(@rule1, :links=)
  end

  test "links method returns expected default value" do
    assert_nil(@rule1.links)
  end

  test "links method returns expected result" do
    omit_if(@@windows && !@@elevated)
    @rule1 = File::Find.new(:name => '*.rb', :links => 2)
    @rule2 = File::Find.new(:name => '*.doc', :links => 1)

    assert_equal([], @rule1.find)
    assert_equal([File.expand_path(@file_doc)], @rule2.find)
  end

  def test_maxdepth_basic
    assert_respond_to(@rule1, :maxdepth)
    assert_respond_to(@rule1, :maxdepth=)
    assert_nil(@rule1.maxdepth)
  end

  # This test is a little uglier because we actually check to make sure
  # we're looking at the right subdir, not just a filename shows up.
  # I did this because I'm a little paranoid about the directory
  # not getting mangled. - jlawler.
  #
  test "find method works on dirs that contain brackets" do
    omit_if(@@windows, 'dirs with brackets test skipped on MS Windows')

    bracket_files = [ 'bracket/a[1]/a.foo', 'bracket/a [2] /b.foo', 'bracket/[a] b [c]/d.foo' ].sort
    bracket_paths = [ 'bracket/a[1]', 'bracket/a [2] ', 'bracket/[a] b [c]', 'bracket/[z] x' ].sort

    bracket_paths.each{ |e| mkpath(e) }
    bracket_files.each{ |e| touch(e) }

    @file_rule = File::Find.new(
      :ftype => 'file',
      :path  => ['bracket']
    )

    @dir_rule = File::Find.new(
      :path => ['bracket'],
      :ftype => 'directory'
    )

    file_results = @file_rule.find.sort

    assert_equal(bracket_files.size,file_results.size)
    path = file_results.first.chomp(bracket_files.first)

    # Confirm the first thing in results is the first thing in bracket_paths
    assert_not_equal(path, file_results.first)
    assert_equal(bracket_files, file_results.map{ |e| e.sub(path,'') }.sort )
    assert_equal(bracket_paths, @dir_rule.find.sort )
  end

  test "find with maxdepth option returns expected results" do
    mkpath('a1/a2/a3')
    touch('a1/a.foo')
    touch('a1/a2/b.foo')
    touch('a1/a2/c.foo')
    touch('a1/a2/a3/d.foo')
    touch('a1/a2/a3/e.foo')
    touch('a1/a2/a3/f.foo')

    @rule2.pattern = "*.foo"
    @rule2.maxdepth = 1
    assert_equal([], @rule2.find)

    @rule2.maxdepth = 2
    assert_equal(['a.foo'], @rule2.find.map{ |e| File.basename(e) })

    @rule2.maxdepth = 3
    assert_equal(['a.foo', 'b.foo', 'c.foo'], @rule2.find.map{ |e| File.basename(e) }.sort)

    @rule2.maxdepth = nil
    assert_equal(
      ['a.foo', 'b.foo', 'c.foo', 'd.foo', 'e.foo', 'f.foo'],
        @rule2.find.map{ |e| File.basename(e) }.sort
    )
  end

  test "find with maxdepth option returns expected results for directories" do
    mkpath('a/b/c')
    @rule2.pattern = "c"

    @rule2.maxdepth = 1
    assert_equal([], @rule2.find)

    @rule2.maxdepth = 2
    assert_equal([], @rule2.find)

    @rule2.maxdepth = 3
    assert_equal(['c'], @rule2.find.map{ |e| File.basename(e) })
  end

  test "mindepth accessor basic functionality" do
    assert_respond_to(@rule1, :mindepth)
    assert_respond_to(@rule1, :mindepth=)
  end

  test "mindepth method returns expected default value" do
    assert_nil(@rule1.mindepth)
  end

  test "find with mindepth option returns expected results" do
    mkpath('a1/a2/a3')
    touch('z.min')
    touch('a1/a.min')
    touch('a1/a2/b.min')
    touch('a1/a2/c.min')
    touch('a1/a2/a3/d.min')
    touch('a1/a2/a3/e.min')
    touch('a1/a2/a3/f.min')

    @rule2.pattern = "*.min"

    @rule2.mindepth = 0
    assert_equal(
      ['a.min', 'b.min', 'c.min', 'd.min', 'e.min', 'f.min', 'z.min'],
      @rule2.find.map{ |e| File.basename(e) }.sort
    )

    @rule2.mindepth = 1
    assert_equal(
      ['a.min', 'b.min', 'c.min', 'd.min', 'e.min', 'f.min', 'z.min'],
      @rule2.find.map{ |e| File.basename(e) }.sort
    )

    @rule2.mindepth = 2
    assert_equal(
      ['a.min', 'b.min', 'c.min', 'd.min', 'e.min', 'f.min'],
      @rule2.find.map{ |e| File.basename(e) }.sort
    )

    @rule2.mindepth = 3
    assert_equal(
      ['b.min', 'c.min', 'd.min', 'e.min', 'f.min'],
      @rule2.find.map{ |e| File.basename(e) }.sort
    )

    @rule2.mindepth = 4
    assert_equal(['d.min', 'e.min', 'f.min'], @rule2.find.map{ |e| File.basename(e) }.sort)

    @rule2.mindepth = 5
    assert_equal([], @rule2.find.map{ |e| File.basename(e) })
  end

  test "find with mindepth option returns expected results for directories" do
    mkpath('a/b/c')
    @rule2.pattern = "a"

    @rule2.mindepth = 1
    assert_equal(['a'], @rule2.find.map{ |e| File.basename(e) })

    @rule2.mindepth = 2
    assert_equal([], @rule2.find)

    @rule2.mindepth = 3
    assert_equal([], @rule2.find)
  end

  test "mount accessor basic functionality" do
    assert_respond_to(@rule1, :mount)
    assert_respond_to(@rule1, :mount=)
  end

  test "mount method returns expected default value" do
    assert_nil(@rule1.mount)
  end

  test "name accessor basic functionality" do
    assert_respond_to(@rule1, :name)
    assert_respond_to(@rule1, :name=)
  end

  test "name method returns expected default value" do
    assert_equal('*.txt', @rule1.name)
  end

  test "pattern accessor basic functionality" do
    assert_respond_to(@rule1, :pattern)
    assert_respond_to(@rule1, :pattern=)
  end

  test "pattern is an alias for name" do
    assert_alias_method(@rule1, :name, :pattern)
    assert_alias_method(@rule1, :name=, :pattern=)
  end

  test "perm accessor basic functionality" do
    assert_respond_to(@rule1, :perm)
    assert_respond_to(@rule1, :perm=)
  end

  test "perm method returns expected default value" do
    assert_nil(@rule1.perm)
  end

  test "perm method returns expected results" do
    File.chmod(0444, @file_rb)
    File.chmod(0644, @file_txt1)

    results = File::Find.new(:name => "test1*", :perm => 0644).find

    assert_equal(1, results.length)
    assert_equal('test1.txt', File.basename(results.first))
  end

  test "perm method works with symbolic permissions" do
    omit_if(@@windows, 'symbolic perm test skipped on MS Windows')

    File.chmod(0664, @file_rb)  # test1.rb
    File.chmod(0644, @file_txt1)  # test1.txt
    results1 = File::Find.new(:name => "test1*", :perm => "g=rw").find
    results2 = File::Find.new(:name => "test1*", :perm => "u=rw").find

    assert_equal(1, results1.length)
    assert_equal(2, results2.length)
    assert_equal('test1.rb', File.basename(results1.first))
    assert_equal(['test1.rb', 'test1.txt'], results2.map{ |e| File.basename(e) }.sort)
  end

  test "prune accessor basic functionality" do
    assert_respond_to(@rule1, :prune)
    assert_respond_to(@rule1, :prune=)
  end

  test "prune method returns expected default value" do
    assert_nil(@rule1.prune)
  end

  test "find method with prune option works as expected" do
    rule = File::Find.new(:name => "*.txt", :prune => 'foo')
    assert_equal('test1.txt', File.basename(rule.find.first))
  end

  test "size accessor basic functionality" do
    assert_respond_to(@rule1, :size)
    assert_respond_to(@rule1, :size=)
  end

  test "size method returns expected default value" do
    assert_nil(@rule1.size)
  end

  test "user accessor basic functionality" do
    assert_respond_to(@rule1, :user)
    assert_respond_to(@rule1, :user=)
  end

  test "user method returns expected default value" do
    assert_nil(@rule1.user)
  end

  test "user method works with numeric id as expected" do
    if @@windows && @@elevated
      uid = @@loguser.gid # Windows assigns the group if any member is an admin
    else
      uid = @@loguser.uid
    end

    @rule1 = File::Find.new(:name => '*.doc', :user => uid)
    assert_equal([File.expand_path(@file_doc)], @rule1.find)
  end

  test "user method works with string as expected" do
    omit_if(@@windows && @@elevated)
    @rule1 = File::Find.new(:name => '*.doc', :user => @@loguser.name)
    assert_equal([File.expand_path(@file_doc)], @rule1.find)
  end

  test "find method with user option using invalid user returns expected results" do
    @rule1 = File::Find.new(:name => '*.doc', :user => 'totallybogus')
    @rule2 = File::Find.new(:name => '*.doc', :user => 99999999)
    assert_equal([], @rule1.find)
    assert_equal([], @rule2.find)
  end

  test "previous method basic functionality" do
    assert_respond_to(@rule1, :previous)
  end

  test "an error is raised if the path does not exist" do
    assert_raise(Errno::ENOENT){ File::Find.new(:path => '/bogus/dir').find }
  end

  test "an error is raised if an invalid option is passed" do
    assert_raise(ArgumentError){ File::Find.new(:bogus => 1) }
    assert_raise(ArgumentError){ File::Find.new(:bogus? => true) }
  end

  def teardown
    rm_rf(@file_rb)
    rm_rf(@file_txt1)
    rm_rf(@file_txt2)
    rm_rf(@file_doc)
    rm_rf(@directory1)
    rm_rf(@directory2)
    rm_rf(@link1) #unless @@windows
    rm_rf('a')
    rm_rf('a1')
    rm_rf('bracket')
    rm_rf('z.min') if File.exist?('z.min')

    @rule1 = nil
    @rule2 = nil
    @file_rb = nil
    @file_txt1 = nil
    @file_txt2 = nil
    @file_doc = nil
  end

  def self.shutdown
    @@windows = nil
    @@jruby   = nil
    @@elevated = nil if @@windows
    @@logroup = nil unless @@windows
  end
end
