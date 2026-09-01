# frozen_string_literal: true

module Metanorma
  module Mko
    # The in-memory bundle: what a projection produces and the Writer
    # serializes. Format-shaped — the component set of MN 116 — so it
    # lives with the format, constructed by the model-side walk in
    # metanorma-document.
    class Result
      attr_reader :document, :units, :edges, :glossary, :bibdata,
                  :bibliography, :identifiers, :assets, :flavor

      def initialize(document:, units:, edges:, glossary:, bibdata:,
                     bibliography:, identifiers:, assets: [], flavor:)
        @document = document
        @units = units
        @edges = edges
        @glossary = glossary
        @bibdata = bibdata
        @bibliography = bibliography
        @identifiers = identifiers
        @assets = assets
        @flavor = flavor
      end
    end
  end
end
