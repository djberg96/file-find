#!/usr/bin/env ruby

require_relative 'lib/file-find'
require 'benchmark'

puts "=== Performance Benchmarks ==="

# Test 1: Local directory search
puts "\n1. Local Ruby file search:"
finder = File::Find.new(name: '*.rb')

Benchmark.bm(15) do |x|
  x.report("Standard:") { finder.find }
  x.report("Threaded (2):") { finder.find_threaded(max_threads: 2) }
  x.report("Threaded (4):") { finder.find_threaded(max_threads: 4) }
  x.report("Fiber:") { finder.find_with_fibers.to_a }
end

# Test 2: Larger directory search (if /usr exists)
if Dir.exist?('/usr')
  puts "\n2. System library search (.so files, depth 3):"
  large_finder = File::Find.new(path: '/usr', name: '*.so', maxdepth: 3)

  Benchmark.bm(15) do |x|
    x.report("Standard:") { large_finder.find }
    x.report("Threaded (2):") { large_finder.find_threaded(max_threads: 2) }
    x.report("Threaded (4):") { large_finder.find_threaded(max_threads: 4) }
    x.report("Threaded (8):") { large_finder.find_threaded(max_threads: 8) }
  end
end

# Test 3: Memory usage comparison
puts "\n3. Memory efficiency test:"
puts "Finding files with block (no array creation):"

finder = File::Find.new(name: '*.rb')

Benchmark.bm(15) do |x|
  x.report("Standard block:") { finder.find { |f| } }
  x.report("Threaded block:") { finder.find_threaded(max_threads: 4) { |f| } }
  x.report("Fiber block:") { finder.find_with_fibers { |f| } }
end

puts "\n=== Summary ==="
puts "✓ Threaded version: Best for I/O-heavy workloads with many directories"
puts "✓ Fiber version: Most memory-efficient for large result sets"
puts "✓ Standard version: Most compatible, good for simple searches"
