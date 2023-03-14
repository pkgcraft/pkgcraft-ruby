# frozen_string_literal: true

require_relative "_pkgcraft_c"
require_relative "pkgcraft/dep"
require_relative "pkgcraft/eapi"
require_relative "pkgcraft/error"
require_relative "pkgcraft/_version"

# Bindings for pkgcraft
module Pkgcraft
  # version requirements for pkgcraft C library
  MINVER = "0.0.7"
  MAXVER = "0.0.7"
end
