# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :test do
  gem "minitest", "~> 5.0", require: false
  gem "rake", "~> 13.0", require: false
  gem "toml-rb", "~> 2.2.0", require: false
end

group :development do
  # lint
  gem "rubocop", require: false
  gem "rubocop-minitest", require: false
  gem "rubocop-rake", require: false

  # coverage
  gem "simplecov", require: false
  gem "simplecov-cobertura", require: false
end
