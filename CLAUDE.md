# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this gem is

`metanorma-mko` implements the **FORMAT** side of MN 116 (Metanorma Knowledge Objects): the wire schema, bundle layout, manifest verification, assets, edition diffs, interlingual alignment, generated JSON Schemas, and the reference MCP server.

The **MODEL** side (projection walk, collection orchestration, flavor resolution, the `Mko.export` / `Mko::Collection.export` entry points) lives in `metanorma-document`, which depends on this gem and **reopens `Metanorma::Mko`**. Consequence: this gem must stay a pure format library — no document-model dependency, and the spec suite must stay pure (committed fixture bundles only). Don't add anything here that needs a document model.

## Commands

```sh
bundle exec rspec                              # full suite (fast, pure — no network, no document model)
bundle exec rspec spec/metanorma/mko/units_spec.rb   # single file
bundle exec rspec -e "writes unitsml.jsonl"    # single example by name
bundle exec rake                               # default task = spec
bundle exec rubocop                            # default cops (no .rubocop.yml); not a CI gate
```

CI: `rspec.yml` runs the suite on Ruby 3.3/3.4; `rake.yml` (cimas-generated) runs `rake`; `edge.yml` runs weekly with `METANORMA_CI_EDGE=1`.

### Dependency sources (Gemfile)

- Default (no env vars): **released gems** — exactly the contract downstream users get. CI and local dev must test this.
- `METANORMA_CI_EDGE=1`: tracks upstream `main` branches (lutaml-model, unitsml) — the bleeding-edge lane.

Never leave a temporary git-source pin in the default lane once the upstream fix has shipped — flip back to the released constraint. **Gemfile.lock is never committed** (gitignored): bundler resolves fresh in CI and locally, so refreshing the lockfile is a local verification step only. Version bumps move `lib/metanorma/mko/version.rb` and the gemspec together.

## Architecture

### Serialization is framework-generated only

Every wire class (`Metanorma::Mko::Schema::*`) is a lutaml-model `Serializable` with JSON mappings. All (de)serialization goes through the framework (`to_json`, `from_json`, mapping blocks) — never hand-rolled `to_h`/`from_hash` key-swapping. Wire names come from the mappings (e.g. `:klass` renders as `"class"`), and `Schema::JsonSchema` generates the published JSON Schema draft 2020-12 documents **from those same classes** — the schema classes are the single source of truth. Polyglot consumers validate against `Metanorma::Mko.json_schemas`; never maintain hand-written copies of the schemas.

### Bundle mechanics vs. component choice

- `Mko::Bundle` (`lib/metanorma/mko/bundle.rb`) is the only code that knows the on-disk layout: one `<short>.mko/` directory, `add_json` / `add_lines` (JSONL, one object per line) / `add_asset`, sha256 per component in `manifest.json`, optional `.zip`.
- `Mko::Writer` (`lib/metanorma/mko/writer.rb`) decides *which* components a document projection produces and feeds them to Bundle. Neither duplicates the other's job; composite exporters must compose both, never reimplement layout.
- `Mko::Export` returns `{path, result}`: composite exporters (collections, alignment) derive from the same in-memory `Result` the bundle was written from — never by reading their own output back.

### Stable anchors are the join key

Units carry stable anchors; content-hash-only units get `h-…` anchors. Cross-edition pairing (`Mko::Diff.between`) and cross-language pairing (`Mko::Alignment.align`, emitting `variant_of` edges) match units by anchor and **never guess** — unmatched or `h-`-anchored units are simply not aligned.

### Language resolution (`Mko::Language`)

W3C XML §2.12 nearest ancestor-or-self `xml:lang`, then a stopword-ratio heuristic (en/fr/es/de) only when no markup is in scope, then the declared document language, then explicit `en` fallback. Every `Resolution` reports provenance (`markup` / `heuristic` / `default` / `fallback`); units carry it as `lang_source`. Consumer-side of standoc#1243 — element-level `xml:lang` wins automatically once the converter emits it.

### MCP server (`Mko::Mcp::Server`)

Reference consumer over any conforming bundle: JSON-RPC 2.0 over stdio, read-only tools (`search_units` / `get_unit` / `walk_edges` / `edition_diff`). Changes to the bundle format must keep this server working — it is the "does the contract hold up" check.

### Loading

Everything is loaded via `autoload` declared in the namespace's parent file (`mko.rb`, `schema.rb`) — no `require_relative` between library files. Follow that pattern for new classes.
