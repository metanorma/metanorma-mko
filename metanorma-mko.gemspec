# frozen_string_literal: true

require_relative "lib/metanorma/mko/version"

Gem::Specification.new do |spec|
  spec.name = "metanorma-mko"
  spec.version = Metanorma::Mko::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "Metanorma Knowledge Objects (MN 116) — the machine serialization format"
  spec.description = "The MN 116 wire contract as code: typed unit schema, bundle layout " \
                     "with manifest verification, hash-addressed assets, edition diffs, " \
                     "interlingual alignment, generated JSON Schemas, and the reference " \
                     "MCP server. metanorma-document composes this gem to export; " \
                     "polyglot consumers validate against the published schemas."
  spec.homepage = "https://github.com/metanorma/metanorma-mko"
  spec.license = "BSD-2-Clause"

  spec.files = Dir["lib/**/*.rb"] + %w[README.adoc LICENSE]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lutaml-model", "~> 0.8"
  spec.add_runtime_dependency "rubyzip"
  spec.add_runtime_dependency "unitsml", "~> 0.6"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1"
end
