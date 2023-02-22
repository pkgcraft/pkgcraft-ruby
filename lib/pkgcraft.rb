# frozen_string_literal: true

require "ffi"
require_relative "pkgcraft/_version"

# Bindings for pkgcraft
module Pkgcraft
  # version requirements for pkgcraft C library
  MINVER = "0.0.7"
  MAXVER = "0.0.7"

  class Error < StandardError; end

  extend FFI::Library
  ffi_lib ["pkgcraft"]
  attach_function :pkgcraft_lib_version, [], :string
end
