# frozen_string_literal: true

require 'date'
require 'sys/admin'

begin
  require 'win32/file'
rescue LoadError
end

class File::Find
  VERSION = '0.5.1'

  VALID_OPTIONS = %i[
    atime ctime follow ftype inum group links maxdepth mindepth mount mtime
    name pattern path perm prune size user
  ].freeze

  attr_accessor :path, :options, :atime, :ctime, :group, :filetest, :follow,
                :ftype, :inum, :links, :maxdepth, :mindepth, :mtime, :name,
                :perm, :prune, :size, :user
  attr_reader :mount, :previous, :filesystem

  alias pattern name
  alias pattern= name=

  def initialize(options = {})
    @options = options
    @atime = @ctime = @ftype = @group = @inum = @links = @mount = @mtime = @perm = @prune = @size = @user = nil
    @follow = true
    @previous = nil
    @maxdepth = @mindepth = nil
    @filetest = []
    validate_and_set_options(options) unless options.empty?
    @filesystem = File.stat(@mount).dev if @mount
    @path ||= Dir.pwd
    @name ||= '*'
  end

  def find
    results = [] unless block_given?
    paths = Array(@path)
    queue = paths.dup
    prune_regex = @prune ? Regexp.new(@prune) : nil

    until queue.empty?
      path = queue.shift
      begin
        Dir.foreach(path) do |file|
          next if %w[. ..].include?(file)
          next if prune_regex&.match?(file)
          file = File.join(path, file)
          stat_method = @follow ? :stat : :lstat
          stat_info = safe_stat(file, stat_method) or next
          next if @mount && stat_info.dev != @filesystem
          next if @links && stat_info.nlink != @links

          if @maxdepth || @mindepth
            depth = file_depth(file, paths)
            next if @maxdepth && depth > @maxdepth
            next if @mindepth && depth < @mindepth
          end

          queue << file if stat_info.directory? && !paths.include?(file)
          next unless File.fnmatch(@name, File.basename(file))
          next unless filetest_pass?(file)
          next unless time_match?(stat_info)
          next if @ftype && File.ftype(file) != @ftype
          next unless group_match?(stat_info)
          next if @inum && stat_info.ino != @inum
          next unless perm_match?(stat_info)
          next unless size_match?(stat_info)
          next unless user_match?(stat_info)

          block_given? ? yield(file) : results << file
          @previous = file unless @previous == file
        end
      rescue Errno::EACCES
        next
      end
    end
    block_given? ? nil : results
  end

  def mount=(mount_point)
    @mount = mount_point
    @filesystem = File.stat(mount_point).dev
  end

  private

  def validate_and_set_options(options)
    options.each do |key, value|
      key = key.to_s.downcase.to_sym
      if key[-1] == '?'
        sym = key
        raise ArgumentError, "invalid option '#{key}'" unless File.respond_to?(sym)
        @filetest << [sym, value]
      else
        raise ArgumentError, "invalid option '#{key}'" unless VALID_OPTIONS.include?(key)
        send("#{key}=", value)
      end
    end
  end

  def safe_stat(file, stat_method)
    File.send(stat_method, file)
  rescue Errno::ENOENT, Errno::EACCES
    nil
  rescue Errno::ELOOP
    stat_method == :lstat ? nil : safe_stat(file, :lstat)
  end

  def file_depth(file, base_paths)
    file_depth = file.split(File::SEPARATOR).reject(&:empty?).length
    base_path = base_paths.find { |tpath| file.include?(tpath) }
    path_depth = base_path.split(File::SEPARATOR).length
    file_depth - path_depth
  end

  def filetest_pass?(file)
    @filetest.all? { |meth, bool| File.send(meth, file) == bool }
  end

  def time_match?(stat_info)
    date1 = Date.parse(Time.now.to_s)
    return true unless @atime || @ctime || @mtime
    return false if @atime && (date1 - Date.parse(stat_info.atime.to_s)).numerator != @atime
    return false if @ctime && (date1 - Date.parse(stat_info.ctime.to_s)).numerator != @ctime
    return false if @mtime && (date1 - Date.parse(stat_info.mtime.to_s)).numerator != @mtime
    true
  end

  def group_match?(stat_info)
    return true unless @group
    if @group.is_a?(String)
      begin
        group_name = File::ALT_SEPARATOR ?
          Sys::Admin.get_group(stat_info.gid, :LocalAccount => true).name :
          Sys::Admin.get_group(stat_info.gid).name
        group_name == @group
      rescue Sys::Admin::Error
        false
      end
    else
      stat_info.gid == @group
    end
  end

  def perm_match?(stat_info)
    return true unless @perm
    if @perm.is_a?(String)
      octal_perm = sym2oct(@perm)
      (stat_info.mode & octal_perm) == octal_perm
    else
      format('%o', stat_info.mode & 0o7777) == format('%o', @perm)
    end
  end

  def size_match?(stat_info)
    return true unless @size
    if @size.is_a?(String)
      regex = /^([><=]+)\s*?(\d+)$/
      match = regex.match(@size)
      raise ArgumentError, "invalid size string: '#{@size}'" if match.nil? || match.captures.include?(nil)
      operator, number = match.captures
      stat_info.size.send(operator.strip, number.strip.to_i)
    else
      stat_info.size == @size
    end
  end

  def user_match?(stat_info)
    return true unless @user
    if @user.is_a?(String)
      begin
        user_name = File::ALT_SEPARATOR ?
          Sys::Admin.get_user(stat_info.uid, :LocalAccount => true).name :
          Sys::Admin.get_user(stat_info.uid).name
        user_name == @user
      rescue Sys::Admin::Error
        false
      end
    else
      stat_info.uid == @user
    end
  end

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
