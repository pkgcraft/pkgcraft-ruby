# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "pkgcraft"

require "minitest/autorun"

begin
  require "simplecov"
  SimpleCov.start

  require "simplecov-cobertura"
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
rescue LoadError
  puts "code coverage disabled"
end
