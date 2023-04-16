# frozen_string_literal: true

# optionally enable coverage support
begin
  require "simplecov"
  # ignore test files
  SimpleCov.start do
    add_filter "/test/"
    enable_coverage :branch
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

# load shared test data
require "toml-rb"
def parse_toml
  data = {}
  Dir.glob("testdata/toml/**/*.toml").each do |path|
    key = File.basename(path, ".toml")
    data[key] = TomlRB.load_file(path)
  end
  data
end
TOML = parse_toml.freeze

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "pkgcraft"

require "minitest/autorun"
