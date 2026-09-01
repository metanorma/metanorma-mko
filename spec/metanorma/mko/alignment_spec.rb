# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Mko::Alignment do
  it "aligns same-anchored units across editions with variant_of" do
    a = File.expand_path("../../fixtures/bundles/requirements.mko", __dir__)
    b = File.expand_path("../../fixtures/bundles/requirements-edition-b.mko", __dir__)
    edges = described_class.align(a, b)
    expect(edges).not_to be_empty
    edges.each do |e|
      expect(e.kind).to eq("variant_of")
      expect(e.from).to start_with("u:")
    end
    expect(edges.map(&:from)).to include("u:req-sensor-accuracy")
    expect(edges.map(&:from)).not_to include(match(/\Ah-/))

    path = described_class.export(a, b)
    lines = File.readlines(path).map { |l| JSON.parse(l) }
    expect(lines.size).to eq(edges.size)
    expect(lines.first["kind"]).to eq("variant_of")
  end
end
