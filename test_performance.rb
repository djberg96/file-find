#!/usr/bin/env ruby

require_relative 'lib/file-find'

puts "Testing File::Find performance optimizations"

# Test basic functionality
puts "\n=== Basic Find Test ==="
finder = File::Find.new(name: '*.rb')
puts "Finder created: #{finder.class}"

begin
  results = finder.find
  puts "Found #{results.length} Ruby files:"
  results.each { |f| puts "  #{f}" }
rescue => e
  puts "Error in basic find: #{e.message}"
  puts e.backtrace.first(5)
end

# Test threaded version with different thread counts
puts "\n=== Threaded Find Test ==="
begin
  start_time = Time.now
  results = finder.find_threaded(max_threads: 2)
  end_time = Time.now
  puts "Threaded find (2 threads): Found #{results.length} files in #{end_time - start_time} seconds"
rescue => e
  puts "Error in threaded find: #{e.message}"
  puts e.backtrace.first(5)
end

# Test fiber version
puts "\n=== Fiber Find Test ==="
begin
  if finder.respond_to?(:find_with_fibers)
    start_time = Time.now
    results = finder.find_with_fibers.to_a
    end_time = Time.now
    puts "Fiber find: Found #{results.length} files in #{end_time - start_time} seconds"
  else
    puts "find_with_fibers method not available"
  end
rescue => e
  puts "Error in fiber find: #{e.message}"
  puts e.backtrace.first(5)
end

# Benchmark different approaches on a larger directory
puts "\n=== Performance Comparison ==="
large_finder = File::Find.new(path: '/usr', name: '*.so', maxdepth: 3)

# Original (single-threaded)
puts "Testing single-threaded approach..."
start_time = Time.now
results1 = large_finder.find
single_time = Time.now - start_time
puts "Single-threaded: #{results1.length} files in #{single_time} seconds"

# Multi-threaded
puts "Testing multi-threaded approach..."
start_time = Time.now
results2 = large_finder.find_threaded(max_threads: 4)
multi_time = Time.now - start_time
puts "Multi-threaded: #{results2.length} files in #{multi_time} seconds"

speedup = single_time / multi_time
puts "Speedup: #{speedup.round(2)}x faster with threads"
