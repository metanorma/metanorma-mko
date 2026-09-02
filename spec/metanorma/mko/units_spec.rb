# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Mko::Units do
  let(:unitsml_xml) do
    <<~XML
      <UnitsML xmlns="https://schema.unitsml.org/unitsml/1.0">
        <UnitSet>
          <Unit id="U_degC" dimensionURL="#NISTd5">
            <UnitSystem>SI</UnitSystem>
            <UnitName>degree Celsius</UnitName>
            <UnitSymbol>°C</UnitSymbol>
          </Unit>
        </UnitSet>
        <DimensionSet>
          <Dimension id="NISTd5">
            <ThermodynamicTemperature symbol="Θ" powerN="1"/>
          </Dimension>
        </DimensionSet>
      </UnitsML>
    XML
  end

  it "parses the UnitsML container into typed register entries" do
    entries = described_class.parse(unitsml_xml)
    expect(entries.size).to eq(1)
    degc = entries.first
    expect(degc.id).to eq("U_degC")
    expect(degc.symbol).to eq("°C")
    expect(degc.name).to eq("degree Celsius")
    expect(degc.dimension).to eq("Θ")
    h = described_class.entry_hash(degc)
    expect(h["id"]).to eq("U_degC")
    expect(h["dimension"]).to eq("Θ")
  end

  it "writes unitsml.jsonl" do
    require "tmpdir"
    require "fileutils"
    dir = Dir.mktmpdir("units")
    begin
      entries = described_class.parse(unitsml_xml)
      described_class.write(entries, dir)
      lines = File.readlines(File.join(dir, "unitsml.jsonl"))
                  .map { |l| JSON.parse(l) }
      expect(lines.first["id"]).to eq("U_degC")
    ensure
      FileUtils.remove_entry(dir)
    end
  end
end
