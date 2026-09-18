# frozen_string_literal: true

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
task default: :spec

namespace :benchmark do
  desc "Shallow-clone the OIML corpus into benchmark/.deps (or set MKO_SAMPLES)"
  task :setup do
    dir = File.expand_path(".deps/mn-samples-oiml", __dir__)
    next if File.directory?(dir)

    sh "git clone --depth 1 " \
       "https://github.com/metanorma/mn-samples-oiml #{dir}"
  end

  desc "MKO export benchmark (TODO.impl/01): runs under the metanorma-document producer bundle, wire gem injected from this checkout"
  task export: :setup do
    repo = ENV["MKO_DOCUMENT_REPO"] ||
           File.expand_path("~/src/mn/metanorma-document")
    abort "metanorma-document checkout not found at #{repo} " \
          "(set MKO_DOCUMENT_REPO)" unless File.directory?(repo)
    lib = File.expand_path("lib", __dir__)
    out = File.expand_path(".deps/out", __dir__)
    Dir.chdir(repo) do
      sh "bundle exec ruby -I #{lib} " \
         "#{File.expand_path('benchmark/export.rb', __dir__)} #{out}"
      sh "bundle exec rspec -I #{lib} " \
         "#{File.expand_path('benchmark/ratchet_spec.rb', __dir__)}"
    end
  end
end
