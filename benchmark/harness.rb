# frozen_string_literal: true

# Shared harness plumbing (TODO.impl/01): corpus resolution, the parse
# seam, and stage measurement. Required by benchmark/export.rb and the
# ratchet spec; never loaded by the gem's pure suite.

require "metanorma/document"
require "metanorma/iso/document"
require "metanorma/mko"
require "nokogiri"
require "benchmark"

module Harness
  SAMPLES = [
    ENV["MKO_SAMPLES"],
    File.expand_path(".deps/mn-samples-oiml", __dir__),
    File.join(Dir.home, "src/mn/mn-samples-oiml"),
  ].compact.find { |d| File.directory?(d) }

  def self.samples!
    return SAMPLES if SAMPLES

    abort "OIML corpus not found (set MKO_SAMPLES or run rake benchmark:setup)"
  end

  def self.rss_kb
    `ps -o rss= -p #{$PROCESS_ID}`.to_i
  end

  # Appends a Stage measuring wall time and allocations of the block.
  def self.measure(stages, name)
    GC.start
    before = GC.stat(:total_allocated_objects)
    seconds = Benchmark.realtime { yield }
    stages << Stage.new(name, seconds,
                        GC.stat(:total_allocated_objects) - before,
                        rss_kb)
  end

  # Mirrors the private Metanorma::Mko.model_from_xml seam (kept local:
  # the harness measures through public API only).
  def self.model_from_xml(xml)
    root = Nokogiri::XML(xml).root
    flavor = root["flavor"]
    klass = nil
    Metanorma::Core::Flavors.table.reverse_each do |entry|
      next if entry.taste?

      candidate = entry.model_root_class or next
      name = entry.name.to_s
      next if flavor && !flavor.empty? && name != flavor

      klass = candidate
      break
    end
    raise "no document model registered for flavor #{flavor.inspect}" unless klass

    klass.from_xml(xml)
  end

  Stage = Struct.new(:name, :seconds, :allocated, :rss_kb)
end
