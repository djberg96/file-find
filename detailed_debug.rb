#!/usr/bin/env ruby

require_relative 'lib/file-find'

puts "=== Detailed Debug ==="

# Test in current directory
finder = File::Find.new(name: '*.rb')

puts "Directories in current path:"
Dir.foreach('.') do |item|
  path = File.join('.', item)
  if File.directory?(path) && item != '.' && item != '..'
    puts "  #{path}"
    puts "    Contents:"
    Dir.foreach(path) do |subitem|
      subpath = File.join(path, subitem)
      if subitem.end_with?('.rb')
        puts "      #{subpath} (RUBY FILE)"
      elsif File.directory?(subpath) && subitem != '.' && subitem != '..'
        puts "      #{subpath}/ (DIR)"
      end
    end
  end
end

puts "\nStandard find process:"
finder.find do |f|
  puts "  Found: #{f}"
end

puts "\nFiber find process:"
finder.find_with_fibers do |f|
  puts "  Found: #{f}"
end
