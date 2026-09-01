# frozen_string_literal: true

require "unitsml/model"

module Metanorma
  module Mko
    # Units register (#55 GAP-1): every unit the document uses, parsed
    # from the source's UnitsML container via the unitsml gem's typed
    # lutaml-model classes. Emitted as units.jsonl — one entry per
    # line — and referenced by id from formula payloads and table
    # columns. Consumers compare on quantity kinds, never unit strings.
    module Units
      Entry = Struct.new(:id, :symbol, :name, :quantity_kind, :dimension,
                         :dimension_url, :si_to, :si_expression,
                         keyword_init: true)

      class << self
        # unitsml_xml: the <UnitsML> container XML (or the inner
        # <UnitSet>). Returns [Entry].
        def parse(unitsml_xml)
          require "nokogiri"
          doc = Nokogiri::XML(unitsml_xml)
          units = doc.remove_namespaces!
                     .xpath("//UnitSet/Unit").map do |node|
            wrap_unit(node)
          end
          dimensions = parse_dimensions(doc)
          units.each do |u|
            dim = dimensions[u.dimension_url]
            u.dimension = dim if dim
          end
          units
        end

        # Write units.jsonl into a bundle; returns the entry list.
        def write(entries, dir)
          path = File.join(dir, "units.jsonl")
          File.write(path, entries.map { |e| JSON.generate(entry_hash(e)) }.join("\n") + "\n")
          entries
        end

        def entry_hash(entry)
          {
            "id" => entry.id,
            "symbol" => entry.symbol,
            "name" => entry.name,
            "quantity_kind" => entry.quantity_kind,
            "dimension" => entry.dimension,
            "si_conversion" => entry.si_to || entry.si_expression ? {
              "to" => entry.si_to,
              "expression" => entry.si_expression,
            } : nil,
          }.compact
        end

        private

        def wrap_unit(node)
          Entry.new(
            id: node["id"],
            symbol: node.xpath(".//UnitSymbol/text()").map(&:text).join,
            name: node.xpath(".//UnitName/text()").map(&:text).join,
            quantity_kind: nil,
            dimension_url: node["dimensionURL"]&.sub("#", ""),
          )
        end

        def parse_dimensions(doc)
          doc.xpath("//Dimension").each_with_object({}) do |d, h|
            h[d["id"]] = dimension_vector(d)
          end
        end

        # SI base-quantity vector: L M T I Θ N J + plane angle
        def dimension_vector(dim)
          parts = []
          { "Length" => "L", "Mass" => "M", "Time" => "T",
            "ElectricCurrent" => "I", "ThermodynamicTemperature" => "Θ",
            "AmountOfSubstance" => "N", "LuminousIntensity" => "J",
            "PlaneAngle" => "φ" }.each do |el, sym|
            node = dim.xpath("./#{el}").first or next
            exp = node["powerN"] || node["powerD"]
            parts << (exp && exp != "1" ? "#{sym}^#{exp}" : sym)
          end
          parts.join("·")
        end
      end
    end
  end
end
