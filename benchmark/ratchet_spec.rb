# frozen_string_literal: true

# The regression ratchet (TODO.impl/01): the smallest corpus document
# through the real export path, asserting the stage list and LOOSE
# wall-time budgets — it catches accidental quadratic behavior, not
# noise. Runs under benchmark/Gemfile (it needs metanorma-document),
# never in the gem's pure suite. Budgets are machine-relative by
# design; revisit only on gross regressions.

require "rspec"
require_relative "harness"
require "fileutils"
require "tmpdir"

RSpec.describe "MKO export ratchet" do
  it "exports the smallest r060 doc through every stage, loosely fast" do
    samples = Harness.samples!
    src = %w[r060/1 r060/2 r060/3].min_by do |d|
      File.size(File.join(samples, "sources", d, "document.xml"))
    end
    xml = File.read(File.join(samples, "sources", src, "document.xml"))

    model = nil
    t_parse = Benchmark.realtime { model = Harness.model_from_xml(xml) }
    expect(model).not_to be_nil
    expect(t_parse).to be < 60

    Dir.mktmpdir do |out|
      projection = nil
      t_project = Benchmark.realtime do
        projection = Metanorma::Mko::Project.call(
          model, assets: Metanorma::Mko::Assets.new
        )
      end
      expect(t_project).to be < 60

      path = nil
      t_write = Benchmark.realtime do
        path = Metanorma::Mko::Writer.write(projection, to: out)
      end
      expect(t_write).to be < 60

      expect(File.file?(File.join(path, "manifest.json"))).to be true
      expect(File.file?(File.join(path, "document.json"))).to be true
      expect(File.size(File.join(path, "units.jsonl"))).to be > 0
    end
  end
end
