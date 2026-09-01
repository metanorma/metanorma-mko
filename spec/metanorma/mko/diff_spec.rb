# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Mko::Diff do
  let(:a) { File.expand_path("../../fixtures/bundles/requirements.mko", __dir__) }
  let(:b) { File.expand_path("../../fixtures/bundles/requirements-edition-b.mko", __dir__) }

  it "emits a structured change set between editions" do
    diff = described_class.between(a, b)
    expect(diff["from"]).to eq("SNR-1")
    changed = diff["changed"]
    restated = changed.find { |u| u["anchor"] == "req-sensor-accuracy" }
    expect(restated["fields"]).to include("text", "statement")
    expect(changed.map { |u| u["anchor"] }).not_to include("req-battery")
  end

  it "writes the diff artifact" do
    require "tmpdir"
    require "fileutils"
    dir = Dir.mktmpdir("mko-diff")
    begin
      path = described_class.export(a, b, to: dir)
      expect(File.basename(path)).to eq("snr-1-to-snr-1.diff.json")
      expect(JSON.parse(File.read(path))["changed"]).to be_an(Array)
    ensure
      FileUtils.remove_entry(dir)
    end
  end
end
