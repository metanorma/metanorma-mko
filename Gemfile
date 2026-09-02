# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# A format gem: the spec suite is pure — committed fixture bundles, no
# document-model dependency. The model side (projection walk, collection
# orchestration) lives in metanorma-document, whose suite covers the
# export integration end to end.
#
# Dependency sources. Default (no env vars): released gems, exactly the
# contract downstream users get — CI and local dev must test that.
# METANORMA_CI_EDGE=1 -> track upstream main branches (bleeding-edge CI).
if ENV["METANORMA_CI_EDGE"]
  gem "lutaml-model", github: "lutaml/lutaml-model", branch: "main"
  gem "unitsml", github: "metanorma/unitsml", branch: "main"
else
  # 0.8.20 yanked; keep the lock below it
  gem "lutaml-model", "~> 0.8.0", "< 0.8.20"
end
