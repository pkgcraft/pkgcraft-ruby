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
  attach_function :pkgcraft_cpv_p, [:pointer], :strptr
  attach_function :pkgcraft_cpv_pf, [:pointer], :strptr
  attach_function :pkgcraft_cpv_pr, [:pointer], :strptr
  attach_function :pkgcraft_cpv_pv, [:pointer], :strptr
  attach_function :pkgcraft_cpv_pvr, [:pointer], :strptr
  attach_function :pkgcraft_cpv_cpn, [:pointer], :strptr
  attach_function :pkgcraft_cpv_intersects, [:pointer, :pointer], :bool
  attach_function :pkgcraft_cpv_intersects_dep, [:pointer, :pointer], :bool
  attach_function :pkgcraft_cpv_hash, [:pointer], :uint64
  attach_function :pkgcraft_cpv_cmp, [:pointer, :pointer], :int
  attach_function :pkgcraft_cpv_str, [:pointer], :strptr

  # dep support
  attach_function :pkgcraft_dep_free, [:pointer], :void
  attach_function :pkgcraft_dep_new, [:string, :pointer], :pointer
  attach_function :pkgcraft_dep_category, [:pointer], :strptr
  attach_function :pkgcraft_dep_package, [:pointer], :strptr
  attach_function :pkgcraft_dep_version, [:pointer], :pointer
  attach_function :pkgcraft_dep_p, [:pointer], :strptr
  attach_function :pkgcraft_dep_pf, [:pointer], :strptr
  attach_function :pkgcraft_dep_pr, [:pointer], :strptr
  attach_function :pkgcraft_dep_pv, [:pointer], :strptr
  attach_function :pkgcraft_dep_pvr, [:pointer], :strptr
  attach_function :pkgcraft_dep_cpn, [:pointer], :strptr
  attach_function :pkgcraft_dep_cpv, [:pointer], :strptr
  attach_function :pkgcraft_dep_intersects, [:pointer, :pointer], :bool
  attach_function :pkgcraft_dep_intersects_cpv, [:pointer, :pointer], :bool
  attach_function :pkgcraft_dep_hash, [:pointer], :uint64
  attach_function :pkgcraft_dep_cmp, [:pointer, :pointer], :int
  attach_function :pkgcraft_dep_str, [:pointer], :strptr

  # version support
  attach_function :pkgcraft_version_free, [:pointer], :void
  attach_function :pkgcraft_version_new, [:string], :pointer
  attach_function :pkgcraft_version_cmp, [:pointer, :pointer], :int
  attach_function :pkgcraft_version_hash, [:pointer], :uint64
  attach_function :pkgcraft_version_intersects, [:pointer, :pointer], :bool
  attach_function :pkgcraft_version_revision, [:pointer], :strptr
  attach_function :pkgcraft_version_op, [:pointer], :int
  attach_function :pkgcraft_version_str, [:pointer], :strptr
  attach_function :pkgcraft_version_str_with_op, [:pointer], :strptr
  attach_function :pkgcraft_version_with_op, [:string], :pointer
end
