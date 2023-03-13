# frozen_string_literal: true

require_relative "pkgcraft/dep"
require_relative "pkgcraft/_version"

# Bindings for pkgcraft
module Pkgcraft
  # version requirements for pkgcraft C library
  MINVER = "0.0.7"
  MAXVER = "0.0.7"

  class Error < StandardError; end
end
