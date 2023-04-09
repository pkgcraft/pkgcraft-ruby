# frozen_string_literal: true

require "ffi"

module Pkgcraft
  # FFI bindings for pkgcraft
  module C
    # version requirements for pkgcraft-c
    MINVER = "0.0.7"
    MAXVER = "0.0.7"

    extend FFI::Library
    ffi_lib ["pkgcraft"]

    # string support
    attach_function :pkgcraft_str_free, [:pointer], :void
    attach_function :pkgcraft_str_array_free, [:pointer, :size_t], :void

    # Return the pkgcraft-c library version.
    def self.version
      attach_function :pkgcraft_lib_version, [], :string

      s, ptr = pkgcraft_lib_version
      pkgcraft_str_free(ptr)
      version = Gem::Version.new(s)

      # verify version requirements for pkgcraft C library
      minver = Gem::Version.new(MINVER)
      maxver = Gem::Version.new(MAXVER)
      raise "pkgcraft C library #{version} fails requirement >=#{minver}" if version < minver
      raise "pkgcraft C library #{version} fails requirement <=#{maxver}" if version > maxver

      version
    end

    private_class_method :version

    # Version of the pkgcraft-c library.
    VERSION = version

    # array length pointer for working with array return values
    class LenPtr < FFI::Struct
      layout :value, :size_t
    end

    # error support
    class Error < FFI::Struct
      layout :message, :string,
             :kind, :int
    end

    attach_function :pkgcraft_error_last, [], Error.by_ref
    attach_function :pkgcraft_error_free, [Error.by_ref], :void

    # config support
    attach_function :pkgcraft_config_new, [], :pointer
    attach_function :pkgcraft_config_free, [:pointer], :void
    attach_function :pkgcraft_config_load_repos_conf, [:pointer, :string, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_config_repos, [:pointer, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_config_repos_set, [:pointer, :int], :pointer

    # repo support
    attach_function :pkgcraft_repos_free, [:pointer, :size_t], :void
    attach_function :pkgcraft_repo_cmp, [:pointer, :pointer], :int
    attach_function :pkgcraft_repo_hash, [:pointer], :uint64
    attach_function :pkgcraft_repo_id, [:pointer], :strptr
    attach_function :pkgcraft_repo_path, [:pointer], :strptr
    attach_function :pkgcraft_repo_categories, [:pointer, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_repo_packages, [:pointer, :string, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_repo_versions, [:pointer, :string, :string, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_repo_len, [:pointer], :uint64
    attach_function :pkgcraft_repo_iter, [:pointer], :pointer
    attach_function :pkgcraft_repo_iter_free, [:pointer], :void
    attach_function :pkgcraft_repo_iter_next, [:pointer], :pointer
    attach_function :pkgcraft_repo_format, [:pointer], :int
    attach_function :pkgcraft_repo_free, [:pointer], :void

    # ebuild repo support
    attach_function :pkgcraft_repo_ebuild_eapi, [:pointer], :pointer
    attach_function :pkgcraft_repo_ebuild_masters, [:pointer, LenPtr.by_ref], :pointer

    # repo set support
    attach_function :pkgcraft_repo_set_repos, [:pointer, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_repo_set_cmp, [:pointer, :pointer], :int
    attach_function :pkgcraft_repo_set_hash, [:pointer], :uint64
    attach_function :pkgcraft_repo_set_iter, [:pointer, :pointer], :pointer
    attach_function :pkgcraft_repo_set_iter_free, [:pointer], :void
    attach_function :pkgcraft_repo_set_iter_next, [:pointer], :pointer
    attach_function :pkgcraft_repo_set_free, [:pointer], :void

    # pkg support
    attach_function :pkgcraft_pkg_format, [:pointer], :int
    attach_function :pkgcraft_pkg_free, [:pointer], :void
    attach_function :pkgcraft_pkg_cpv, [:pointer], :pointer
    attach_function :pkgcraft_pkg_eapi, [:pointer], :pointer
    attach_function :pkgcraft_pkg_repo, [:pointer], :pointer
    attach_function :pkgcraft_pkg_version, [:pointer], :pointer
    attach_function :pkgcraft_pkg_cmp, [:pointer, :pointer], :int
    attach_function :pkgcraft_pkg_hash, [:pointer], :uint64
    attach_function :pkgcraft_pkg_str, [:pointer], :strptr

    # eapi support
    attach_function :pkgcraft_eapi_as_str, [:pointer], :strptr
    attach_function :pkgcraft_eapi_cmp, [:pointer, :pointer], :int
    attach_function :pkgcraft_eapi_has, [:pointer, :string], :bool
    attach_function :pkgcraft_eapi_hash, [:pointer], :uint64
    attach_function :pkgcraft_eapis_official, [LenPtr.by_ref], :pointer
    attach_function :pkgcraft_eapis, [LenPtr.by_ref], :pointer
    attach_function :pkgcraft_eapis_range, [:string, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_eapis_free, [:pointer, :size_t], :void

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
    attach_function :pkgcraft_dep_blocker, [:pointer], :int
    attach_function :pkgcraft_dep_blocker_from_str, [:string], :int
    attach_function :pkgcraft_dep_category, [:pointer], :strptr
    attach_function :pkgcraft_dep_package, [:pointer], :strptr
    attach_function :pkgcraft_dep_version, [:pointer], :pointer
    attach_function :pkgcraft_dep_slot, [:pointer], :strptr
    attach_function :pkgcraft_dep_subslot, [:pointer], :strptr
    attach_function :pkgcraft_dep_slot_op, [:pointer], :int
    attach_function :pkgcraft_dep_slot_op_from_str, [:string], :int
    attach_function :pkgcraft_dep_use_deps, [:pointer, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_dep_repo, [:pointer], :strptr
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
    attach_function :pkgcraft_version_op_from_str, [:string], :int
    attach_function :pkgcraft_version_str, [:pointer], :strptr
    attach_function :pkgcraft_version_str_with_op, [:pointer], :strptr
    attach_function :pkgcraft_version_with_op, [:string], :pointer
  end
end
