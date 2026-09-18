#!/usr/bin/env ruby
# frozen_string_literal: true

# MKO export benchmark (TODO.impl/01). Drives the production export
# path — Metanorma::Mko.export over in-tree compiled XML, the exact
# driver the konneal / oimlsmart-rag ingests run — and reports wall
# time, allocated objects, and RSS per stage, plus bundle size.
#
# Stages: parse (XML -> model trees), project (the MN 116 walk),
# serialize (sink estimate: to_json over the bulk components), write
# (bundle + manifest + hashes). Absolute numbers are machine-relative;
# benchmark/ratchet_spec.rb guards the shape, not the values.
#
#   rake benchmark:export
#   MKO_SAMPLES=<corpus> ruby benchmark/export.rb [out_dir]

require "bundler/setup"
require_relative "harness"
require "fileutils"

DOCS = %w[r060/1 r060/2 r060/3].freeze
samples = Harness.samples!
out = ARGV[0] || File.expand_path(".deps/out", __dir__)
FileUtils.mkdir_p(out)

def bundle_kb(path)
  `du -sk #{path}`.split.first.to_i
end

def report(title, stages, path)
  width = stages.map { |s| s.name.length }.max
  puts "  #{title}  [#{File.basename(path.to_s)}]"
  stages.each do |s|
    printf("    %-#{width}s  %8.2fs  %12d allocs  %6d MB rss\n",
           s.name, s.seconds, s.allocated, s.rss_kb / 1024)
  end
  printf("    %-#{width}s  %8.2fs\n", "total", stages.sum(&:seconds))
  puts "    #{' ' * width}  bundle: #{bundle_kb(path)} KB"
end

peak = 0
DOCS.each do |src|
  xml = File.read(File.join(samples, "sources", src, "document.xml"))
  pres = File.read(
    File.join(samples, "sources", src, "document.presentation.xml")
  )
  stages = []
  model = pres_model = projection = path = nil
  Harness.measure(stages, "parse") do
    model = Harness.model_from_xml(xml)
    pres_model = Harness.model_from_xml(pres)
  end
  Harness.measure(stages, "project") do
    projection = Metanorma::Mko::Project.call(
      model, presentation: pres_model, assets: Metanorma::Mko::Assets.new
    )
  end
  Harness.measure(stages, "serialize (sink)") do
    [projection.document.to_json, projection.units.map(&:to_json),
     projection.edges.map(&:to_json)]
  end
  Harness.measure(stages, "write") do
    path = Metanorma::Mko::Writer.write(projection, to: out)
  end
  peak = [peak, stages.map(&:rss_kb).max].max
  report(src, stages, path)
end

collection = File.join(samples, "sources", "r060", "collection.yml")
if File.file?(collection)
  stages = []
  path = nil
  Harness.measure(stages, "collection (members + family)") do
    result = Metanorma::Mko::Collection.export(collection, to: out)
    path = result.collection_bundle
  end
  peak = [peak, stages.map(&:rss_kb).max].max
  report("r060 collection.yml", stages, path)
end

puts "peak RSS: #{peak / 1024} MB (sampled at stage boundaries)"
