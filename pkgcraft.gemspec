# frozen_string_literal: true

require_relative "lib/pkgcraft/version"

Gem::Specification.new do |spec|
  spec.name = "pkgcraft"
  spec.version = Pkgcraft::VERSION
  spec.authors = ["Tim Harder"]
  spec.email = ["radhermit@gmail.com"]

  spec.summary = "Ruby bindings for pkgcraft"
  spec.homepage = "https://github.com/pkgcraft/pkgcraft-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/pkgcraft/pkgcraft-ruby.git"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi", "~> 1.15"
end
