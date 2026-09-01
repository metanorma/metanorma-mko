# frozen_string_literal: true

require "metanorma/mko"
require "metanorma/document"
require "metanorma/iso/document"
require "metanorma/ogc/document"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
