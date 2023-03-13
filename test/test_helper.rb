# frozen_string_literal: true

# optionally enable coverage support
begin
  require "simplecov"
  # ignore test files
  SimpleCov.start do
    add_filter "/test/"
  end

  # optionally enable codecov support
  begin
    require "simplecov-cobertura"
    SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  rescue LoadError
    puts "codecov support disabled"
  end
rescue LoadError
  puts "code coverage disabled"
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "pkgcraft"

require "minitest/autorun"
