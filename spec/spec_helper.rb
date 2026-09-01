# frozen_string_literal: true

require "metanorma/mko"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
