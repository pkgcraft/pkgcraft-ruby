# frozen_string_literal: true

# optionally enable coverage support
begin
  require "simplecov"
  # ignore test files
  SimpleCov.start do
    add_filter "/test/"
    enable_coverage :branch

    if ENV["CI"]
      require "simplecov-cobertura"
      formatter SimpleCov::Formatter::CoberturaFormatter
    else
      require "simplecov-html"
      formatter SimpleCov::Formatter::HTMLFormatter
    end
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
TESTDATA_TOML = parse_toml.freeze

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "pkgcraft"

# load repos from shared test data
def load_repos
  config = Pkgcraft::Configs::Config.new
  Dir.glob("testdata/repos/valid/*").each do |path|
    config.add_repo(path, id: File.basename(path))
  end
  config
end
TESTDATA_CONFIG = load_repos

require "minitest/autorun"
