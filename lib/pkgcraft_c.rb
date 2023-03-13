# frozen_string_literal: true

require "ffi"

# FFI bindings for pkgcraft
module C
  extend FFI::Library
  ffi_lib ["pkgcraft"]
  attach_function :pkgcraft_lib_version, [], :string

  attach_function :pkgcraft_cpv_free, [:pointer], :void
  attach_function :pkgcraft_cpv_new, [:string], :pointer
  attach_function :pkgcraft_cpv_category, [:pointer], :string
  attach_function :pkgcraft_cpv_package, [:pointer], :string
end
