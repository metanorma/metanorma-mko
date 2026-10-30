# frozen_string_literal: true

require "metanorma/mko"
# The model side composes metanorma-document; the export specs parse
# flavor documents, so the suite mirrors that suite's flavor-model
# requires.
require "metanorma/document"
require "metanorma/standoc"
require "metanorma/iso/document"
require "metanorma/itu/document"
require "metanorma/ogc/document"
require "metanorma/mko/model"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

Lutaml::Model::Config.configure do |config|
  config.xml_adapter_type = :nokogiri
end
