# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# The wire contract specs are pure — committed fixture bundles. The
# model side (projection walk, collection orchestration, export) is
# served by metanorma-document; its specs parse ISO/ITU/OGC/Standoc
# flavor documents, so the suite carries the same dev-time flavor
# pins as the metanorma-document suite.
gem "isodoc", github: "metanorma/isodoc", branch: "main"
gem "metanorma-core", "~> 0.2.5.pre.alpha" # published flavor/taste table (metanorma-core#18)
gem "metanorma-iso", github: "metanorma/metanorma-iso", branch: "main"
gem "metanorma-itu", github: "metanorma/metanorma-itu", branch: "main"
gem "metanorma-mirror", github: "metanorma/metanorma-mirror", branch: "main"
# model-side move: the gemspec floor is unreleased until both sides of
# the decycle land; pin the removal branch until then
gem "metanorma-document", github: "metanorma/metanorma-document",
    branch: "chore/remove-mko-model-side"
gem "metanorma-ogc", github: "metanorma/metanorma-ogc", branch: "main"
# TEMPORARY pin: svgmap/imagemap/columnbreak section wiring
gem "metanorma-standoc", github: "metanorma/metanorma-standoc", branch: "main"
#
# Dependency sources. Default (no env vars): released gems, exactly the
# contract downstream users get — CI and local dev must test that.
# METANORMA_CI_EDGE=1 -> track upstream main branches (bleeding-edge CI).
if ENV["METANORMA_CI_EDGE"]
  gem "lutaml-model", github: "lutaml/lutaml-model", branch: "main"
  gem "unitsml", github: "metanorma/unitsml", branch: "main"
else
  gem "leptris", "~> 1.9"
  gem "lutaml-model", "~> 0.8.0", ">= 0.8.22", "< 0.9"
  gem "moxml", "~> 0.5.30"
end
