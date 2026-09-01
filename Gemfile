# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

gemspec

# The model side (projection walk, collection orchestration) lives in
# metanorma-document; the format specs build bundles through it.
gem "metanorma-document", github: "metanorma/metanorma-document", branch: "feat/model-validation-l1-declarations"
gem "metanorma-iso", github: "metanorma/metanorma-iso", branch: "feat/model-validation-migration"
gem "metanorma-ogc", github: "metanorma/metanorma-ogc", branch: "feat/move-ogc-document"
gem "metanorma-core", github: "metanorma/metanorma-core", branch: "feat/flavor-table"
gem "lutaml-model", "~> 0.8.0", "< 0.8.20" # 0.8.20 yanked
