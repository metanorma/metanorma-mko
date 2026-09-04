# frozen_string_literal: true

require "lutaml/model"
require "json"
require "digest"

module Metanorma
  # Metanorma Knowledge Objects (MKO, MN 116) — the machine
  # serialization of a Metanorma document as a bundle of typed,
  # addressable knowledge objects (metanorma/metanorma#592). A derived
  # projection over a typed document model: like a rendering, never a
  # source format.
  #
  # This gem owns the FORMAT (the MN 116 contract): wire schema,
  # bundle layout + manifest verification, assets, alignment, diffs,
  # the generated JSON Schemas, and the reference MCP server.
  # metanorma-document reopens this module with the MODEL side — the
  # projection walk, collection orchestration, flavor resolution — and
  # composes this gem to export.
  module Mko
    autoload :VERSION, "metanorma/mko/version"
    autoload :Schema, "metanorma/mko/schema"
    autoload :Bundle, "metanorma/mko/bundle"
    autoload :Writer, "metanorma/mko/writer"
    autoload :Export, "metanorma/mko/export"
    autoload :Result, "metanorma/mko/result"
    autoload :Assets, "metanorma/mko/assets"
    autoload :Alignment, "metanorma/mko/alignment"
    autoload :Diff, "metanorma/mko/diff"
    autoload :Mcp, "metanorma/mko/mcp"
    autoload :Units, "metanorma/mko/units"
    autoload :Language, "metanorma/mko/language"

    autoload :VERSION, "metanorma/mko/version"

    SCHEMA = "metanorma-mko"
    SCHEMA_VERSION = VERSION

    class << self
      # The published wire contract, generated from the schema classes
      # (single source of truth): name => JSON Schema draft 2020-12.
      def json_schemas
        Schema::JsonSchema.all
      end

      # Canonical short-id derivation (one rule, documents and
      # collections alike).
      def slug(canonical)
        canonical.to_s.tr(" ", "-").gsub(/[^A-Za-z0-9.\-]/, "")
                 .squeeze("-").downcase
      end
    end
  end
end
