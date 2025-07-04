# frozen_string_literal: true

require 'date'
require 'sys/admin'

begin
  require 'win32/file'
rescue LoadError
  # Do nothing, not required, just nicer.
end

# The File::Find class encapsulates 'rules' that you create and use to find
# files on your filesystem.
class File::Find
  # The version of the file-find library
  VERSION = '0.5.2'

  # :stopdoc:
  VALID_OPTIONS = %w[
    atime
    ctime
    follow
    ftype
    inum
    group
    links
    maxdepth
    mindepth
    mount
    mtime
    name
    pattern
    path
    perm
    prune
    size
    user
  ].freeze
  # :startdoc:

  # The starting path(s) for the search. The default is the current directory.
  # This can be a single path or an array of paths.
  #
  attr_accessor :path

  # The list of options passed to the constructor and/or used by the
  # File::Find#find method.
  #
  attr_accessor :options

  # Limits searches by file access time, where the value you supply is the
  # number of days back from the time that the File::Find#find method was
  # called.
  #
  attr_accessor :atime

  # Limits searches by file change time, where the value you supply is the
  # number of days back from the time that the File::Find#find method was
  # called.
  #
  attr_accessor :ctime

  # Limits searches to files that belong to a specific group, where the
  # group can be either a group name or ID.
  #
  attr_accessor :group

  # An array of two element arrays for storing FileTest methods and their
  # boolean value.
  #
  attr_accessor :filetest

  # Controls the behavior of how symlinks are followed. If set to true (the
  # default), then follows the file pointed to. If false, it considers the
  # symlink itself.
  #
  attr_accessor :follow

  # Limits searches to specific types of files. The possible values here are
  # those returned by the File.ftype method.
  #
  attr_accessor :ftype

  # Limits search to a file with a specific inode number.
  #
  attr_accessor :inum

  # Limits search to files with the specified number of links.
  #
  attr_accessor :links

  # Limits search to a maximum depth into the tree relative to the starting
  # search directory.
  #
  attr_accessor :maxdepth

  # Limits searches to a minimum depth into the tree relative to the starting
  # search directory.
  #
  attr_accessor :mindepth

  # Limits searches to the same filesystem as the specified directory. For
  # Windows users, this refers to the volume.
  #
  attr_reader :mount

  # Limits searches by file modification time, where the value you supply is
  # the number of days back from the time that the File::Find#find method was
  # called.
  #
  attr_accessor :mtime

  # The name pattern used to limit file searches. The patterns that are legal
  # for File.fnmatch are legal here. The default is '*', i.e. everything.
  #
  attr_accessor :name

  # Limits searches to files which have permissions that match the octal
  # value that you provide. For purposes of this comparison, only the user,
  # group, and world settings are used.
  #
  # You may optionally use symbolic permissions, e.g. "g+rw", "u=rwx", etc.
  #
  # MS Windows only recognizes two modes, 0644 and 0444.
  #
  attr_accessor :perm

  # Skips files or directories that match the string provided as an argument.
  #
  attr_accessor :prune

  # If the value passed is an integer, this option limits searches to files
  # that match the size, in bytes, exactly. If a string is passed, you can
  # use the standard comparable operators to match files, e.g. ">= 200" would
  # limit searches to files greater than or equal to 200 bytes.
  #
  attr_accessor :size

  # Limits searches to files that belong to a specific user, where the user
  # can be either a user name or an ID.
  #
  attr_accessor :user

  # The file that matched previously in the current search.
  #
  attr_reader :previous

  alias pattern name
  alias pattern= name=

  # Creates and returns a new File::Find object. The options set for this
  # object serve as the rules for determining what files the File::Find#find
  # method will search for.
  #
  # In addition to the standard list of valid options, you may also use
  # FileTest methods as options, setting their value to true or false.
  #
  # Example:
  #
  #    rule = File::Find.new(
  #       :name      => "*.rb",
  #       :follow    => false,
  #       :path      => ['/usr/local/lib', '/opt/local/lib'],
  #       :readable? => true
  #    )
  #
  def initialize(options = {})
    @options = options

    @atime  = nil
    @ctime  = nil
    @ftype  = nil
    @group  = nil
    @follow = true
    @inum   = nil
    @links  = nil
    @mount  = nil
    @mtime  = nil
    @perm   = nil
    @prune  = nil
    @size   = nil
    @user   = nil

    @previous = nil
    @maxdepth = nil
    @mindepth = nil
    @filetest = []

    validate_and_set_options(options) unless options.empty?

    @filesystem = File.stat(@mount).dev if @mount

    @path ||= Dir.pwd
    @name ||= '*'
  end

  # Executes the find based on the rules you set for the File::Find object.
  # In block form, yields each file in turn that matches the specified rules.
  # In non-block form it will return an array of matches instead.
  #
  # Example:
  #
  #   rule = File::Find.new(
  #      :name    => "*.rb",
  #      :follow  => false,
  #      :path    => ['/usr/local/lib', '/opt/local/lib']
  #   )
  #
  #   rule.find{ |f|
  #      puts f
  #   }
  #
  def find
    results = [] unless block_given?
    paths   = Array(@path)
    queue   = paths.dup

    if @prune
      prune_regex = Regexp.new(@prune)
    else
      prune_regex = nil
    end

    # rubocop:disable Metrics/BlockLength
    until queue.empty?
      path = queue.shift
      begin
        Dir.foreach(path) do |file|
          next if file == '.'
          next if file == '..'

          if prune_regex && prune_regex.match(file)
            next
          end

          file = File.join(path, file)

          stat_method = @follow ? :stat : :lstat
          # Skip files we cannot access, stale links, etc.
          begin
            stat_info = File.send(stat_method, file)
          rescue Errno::ENOENT, Errno::EACCES
            next
          rescue Errno::ELOOP
            if stat_method.to_s != 'lstat'
              stat_method = :lstat # Handle recursive symlinks
              retry
            end
          end

          if @mount && stat_info.dev != @filesystem
            next
          end

          if @links && stat_info.nlink != @links
            next
          end

          if @maxdepth || @mindepth
            file_depth = file.split(File::SEPARATOR).reject(&:empty?).length
            current_base_path = [@path].flatten.find{ |tpath| file.include?(tpath) }
            path_depth = current_base_path.split(File::SEPARATOR).length

            depth = file_depth - path_depth

            if @maxdepth && depth > @maxdepth
              if stat_info.directory? && !paths.include?(file)
                queue << file
              end
              next
            end

            if @mindepth && depth < @mindepth
              if stat_info.directory? && !paths.include?(file)
                queue << file
              end
              next
            end
          end

          # Add directories back onto the list of paths to search unless
          # they've already been added
          #
          if stat_info.directory? && !paths.include?(file)
            queue << file
          end

          next unless File.fnmatch?(@name, File.basename(file))

          if !@filetest.empty? && !@filetest.all? { |meth, bool| File.send(meth, file) == bool }
            next
          end

          if @atime || @ctime || @mtime
            now = Date.today
            next if @atime && (now - Date.parse(stat_info.atime.to_s)).to_i != @atime
            next if @ctime && (now - Date.parse(stat_info.ctime.to_s)).to_i != @ctime
            next if @mtime && (now - Date.parse(stat_info.mtime.to_s)).to_i != @mtime
          end

          if @ftype && File.ftype(file) != @ftype
            next
          end

          if @group
            if @group.is_a?(String)
              if File::ALT_SEPARATOR
                begin
                  next unless Sys::Admin.get_group(stat_info.gid, :LocalAccount => true).name == @group
                rescue Sys::Admin::Error
                  next
                end
              else
                begin
                  next unless Sys::Admin.get_group(stat_info.gid).name == @group
                rescue Sys::Admin::Error
                  next
                end
              end
            else
              next unless stat_info.gid == @group
            end
          end

          if @inum && stat_info.ino != @inum
            next
          end

          # Note that only 0644 and 0444 are supported on MS Windows.
          if @perm
            if @perm.is_a?(String)
              octal_perm = sym2oct(@perm)
              next unless stat_info.mode & octal_perm == octal_perm
            else
              next unless format('%o', stat_info.mode & 07777) == format('%o', @perm)
            end
          end

          # Allow plain numbers, or strings for comparison operators.
          if @size
            if @size.is_a?(String)
              regex = /^([><=]+)\s*?(\d+)$/
              match = regex.match(@size)

              if match.nil? || match.captures.include?(nil)
                raise ArgumentError, "invalid size string: '#{@size}'"
              end

              operator = match.captures.first.strip
              number   = match.captures.last.strip.to_i

              next unless stat_info.size.send(operator, number)
            else
              next unless stat_info.size == @size
            end
          end

          if @user
            if @user.is_a?(String)
              if File::ALT_SEPARATOR
                begin
                  next unless Sys::Admin.get_user(stat_info.uid, :LocalAccount => true).name == @user
                rescue Sys::Admin::Error
                  next
                end
              else
                begin
                  next unless Sys::Admin.get_user(stat_info.uid).name == @user
                rescue Sys::Admin::Error
                  next
                end
              end
            else
              next unless stat_info.uid == @user
            end
          end

          if block_given?
            yield file
          else
            results << file
          end

          @previous = file unless @previous == file
        end
      rescue Errno::EACCES
        next # Skip inaccessible directories
      end
    end
    # rubocop:enable Metrics/BlockLength

    block_given? ? nil : results
  end

  # Limits searches to the same file system as the specified +mount_point+.
  #
  def mount=(mount_point)
    @mount = mount_point
    @filesystem = File.stat(mount_point).dev
  end

  private

  # This validates that the keys are valid. If they are, it sets the value
  # of that key's corresponding method to the given value. If a key ends
  # with a '?', it's validated as a File method.
  #
  def validate_and_set_options(options)
    options.each do |key, value|
      key = key.to_s.downcase

      if key[-1].chr == '?'
        sym = key.to_sym

        unless File.respond_to?(sym)
          raise ArgumentError, "invalid option '#{key}'"
        end

        @filetest << [sym, value]
      else
        unless VALID_OPTIONS.include?(key)
          raise ArgumentError, "invalid option '#{key}'"
        end

        send("#{key}=", value)
      end
    end
  end

  # Converts a symoblic permissions mode into its octal equivalent.
  #--
  # Taken almost entirely from ruby-talk: 96956 (Hal Fulton).
  #
  def sym2oct(str)
    left  = {'u' => 0700, 'g' => 0070, 'o' => 0007, 'a' => 0777}
    right = {'r' => 0444, 'w' => 0222, 'x' => 0111}
    regex = /([ugoa]+)([+-=])([rwx]+)/

    cmds = str.split(',')

    perm = 0

    cmds.each do |cmd|
      match = cmd.match(regex)
      raise "Invalid symbolic permissions: '#{str}'" if match.nil?

      who, what, how = match.to_a[1..]

      who  = who.chars.inject(0){ |num, b| num | left[b] }
      how  = how.chars.inject(0){ |num, b| num | right[b] }
      mask = who & how

      case what
        when '+'
          perm |= mask
        when '-'
          perm &= ~mask
        when '='
          perm = mask
      end
    end

    perm
  end
end
