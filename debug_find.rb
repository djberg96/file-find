#!/usr/bin/env ruby

require_relative 'lib/file-find'

puts "=== Debugging Threaded Find ==="

# Test in current directory
finder = File::Find.new(name: '*.rb')

puts "Standard find results:"
std_results = finder.find
std_results.each { |f| puts "  #{f}" }
puts "Total: #{std_results.length}"

puts "\nThreaded find results:"
threaded_results = finder.find_threaded(max_threads: 2)
threaded_results.each { |f| puts "  #{f}" }
puts "Total: #{threaded_results.length}"

puts "\nFiber find results:"
fiber_results = []
finder.find_with_fibers { |f| fiber_results << f }
fiber_results.each { |f| puts "  #{f}" }
puts "Total: #{fiber_results.length}"

# Test if they find the same files
puts "\nComparison:"
puts "Standard == Threaded: #{std_results.sort == threaded_results.sort}"
puts "Standard == Fiber: #{std_results.sort == fiber_results.sort}"

if std_results.sort != threaded_results.sort
  puts "Missing in threaded: #{(std_results - threaded_results).sort}"
  puts "Extra in threaded: #{(threaded_results - std_results).sort}"
end
