# frozen_string_literal: true

require "ffi"

# FFI bindings for pkgcraft
module C
  extend FFI::Library

  ffi_lib ["pkgcraft"]

  # generic library support
  attach_function :pkgcraft_lib_version, [], :string

  # string support
  attach_function :pkgcraft_str_free, [:pointer], :void

  # cpv support
  attach_function :pkgcraft_cpv_free, [:pointer], :void
  attach_function :pkgcraft_cpv_new, [:string], :pointer
  attach_function :pkgcraft_cpv_category, [:pointer], :strptr
  attach_function :pkgcraft_cpv_package, [:pointer], :strptr
  attach_function :pkgcraft_cpv_version, [:pointer], :pointer
  attach_function :pkgcraft_cpv_hash, [:pointer], :uint64
  attach_function :pkgcraft_cpv_cmp, [:pointer, :pointer], :int
  attach_function :pkgcraft_cpv_str, [:pointer], :strptr

  # version support
  attach_function :pkgcraft_version_free, [:pointer], :void
  attach_function :pkgcraft_version_new, [:string], :pointer
  attach_function :pkgcraft_version_cmp, [:pointer, :pointer], :int
  attach_function :pkgcraft_version_hash, [:pointer], :uint64
  attach_function :pkgcraft_version_revision, [:pointer], :strptr
  attach_function :pkgcraft_version_str, [:pointer], :strptr
end
