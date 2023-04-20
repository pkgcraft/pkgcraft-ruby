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
    VERSION = version.freeze

    # array length pointer for working with array return values
    class LenPtr < FFI::Struct
      layout :value, :size_t
    end

    # DepSet wrapper
    class DepSet < FFI::ManagedStruct
      layout :unit, :int,
             :kind, :int,
             :ptr,  :pointer

      def self.release(ptr)
        C.pkgcraft_dep_set_free(ptr)
      end
    end

    # DepSpec wrapper
    class DepSpec < FFI::ManagedStruct
      layout :unit, :int,
             :kind, :int,
             :ptr,  :pointer

      def self.release(ptr)
        C.pkgcraft_dep_spec_free(ptr)
      end
    end

    # error support
    class Error < FFI::ManagedStruct
      layout :message, :string,
             :kind, :int

      def self.release(ptr)
        C.pkgcraft_error_free(ptr)
      end
    end

    attach_function :pkgcraft_error_last, [], Error.by_ref
    attach_function :pkgcraft_error_free, [:pointer], :void

    # logging support
    class PkgcraftLog < FFI::ManagedStruct
      layout :message, :string,
             :level, :int

      def self.release(ptr)
        C.pkgcraft_log_free(ptr)
      end
    end

    # Wrapper for config objects
    class Config < FFI::AutoPointer
      def self.release(ptr)
        C.pkgcraft_config_free(ptr)
      end
    end

    # Wrapper for Cpv objects
    class Cpv < FFI::AutoPointer
      def self.release(ptr)
        C.pkgcraft_cpv_free(ptr)
      end
    end

    # Wrapper for version objects
    class Version < FFI::AutoPointer
      def self.release(ptr)
        C.pkgcraft_version_free(ptr)
      end
    end

    # Wrapper for Dep objects
    class Dep < FFI::AutoPointer
      def self.release(ptr)
        C.pkgcraft_dep_free(ptr)
      end
    end

    # Wrapper for Restrict objects
    class Restrict < FFI::AutoPointer
      def self.release(ptr)
        C.pkgcraft_restrict_free(ptr)
      end
    end

    # Wrapper for Pkg objects
    class Pkg < FFI::AutoPointer
      def self.release(ptr)
        C.pkgcraft_pkg_free(ptr)
      end
    end

    # Wrapper for RepoSet objects
    class RepoSet < FFI::AutoPointer
      def self.release(ptr)
        C.pkgcraft_repo_set_free(ptr)
      end
    end

    # type aliases
    typedef :pointer, :repo
    typedef :pointer, :eapi
    typedef DepSet.by_ref, :DepSet
    typedef DepSpec.by_ref, :DepSpec

    callback :log_callback, [PkgcraftLog.by_ref], :void
    attach_function :pkgcraft_logging_enable, [:log_callback], :void
    attach_function :pkgcraft_log_free, [:pointer], :void
    attach_function :pkgcraft_log_test, [PkgcraftLog.by_ref], :void

    # config support
    attach_function :pkgcraft_config_new, [], Config
    attach_function :pkgcraft_config_free, [:pointer], :void
    attach_function :pkgcraft_config_load_repos_conf, [Config, :string, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_config_repos, [Config, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_config_repos_set, [Config, :int], RepoSet
    attach_function :pkgcraft_config_add_repo, [Config, :repo], :repo
    attach_function :pkgcraft_config_add_repo_path, [Config, :string, :int, :string], :repo

    # repo support
    attach_function :pkgcraft_repos_free, [:pointer, :size_t], :void
    attach_function :pkgcraft_repo_cmp, [:repo, :repo], :int
    attach_function :pkgcraft_repo_hash, [:repo], :uint64
    attach_function :pkgcraft_repo_id, [:repo], :strptr
    attach_function :pkgcraft_repo_path, [:repo], :strptr
    attach_function :pkgcraft_repo_contains_path, [:repo, :string], :bool
    attach_function :pkgcraft_repo_categories, [:repo, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_repo_packages, [:repo, :string, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_repo_versions, [:repo, :string, :string, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_repo_len, [:repo], :uint64
    attach_function :pkgcraft_repo_is_empty, [:repo], :bool
    attach_function :pkgcraft_repo_iter, [:repo], :pointer
    attach_function :pkgcraft_repo_iter_free, [:pointer], :void
    attach_function :pkgcraft_repo_iter_next, [:pointer], Pkg
    attach_function :pkgcraft_repo_iter_restrict, [:repo, Restrict], :pointer
    attach_function :pkgcraft_repo_iter_restrict_free, [:repo], :void
    attach_function :pkgcraft_repo_iter_restrict_next, [:pointer], Pkg
    attach_function :pkgcraft_repo_format, [:repo], :int
    attach_function :pkgcraft_repo_free, [:repo], :void
    attach_function :pkgcraft_repo_from_path, [:string, :int, :string, :bool], :repo

    # ebuild repo support
    attach_function :pkgcraft_repo_ebuild_eapi, [:repo], :eapi
    attach_function :pkgcraft_repo_ebuild_masters, [:repo, LenPtr.by_ref], :pointer

    # temp ebuild repo
    attach_function :pkgcraft_repo_ebuild_temp_new, [:string, :pointer], :pointer
    attach_function :pkgcraft_repo_ebuild_temp_path, [:pointer], :string
    attach_function :pkgcraft_repo_ebuild_temp_free, [:pointer], :void
    attach_function :pkgcraft_repo_ebuild_temp_create_ebuild, [:pointer, :string, :pointer, :uint64], :strptr
    attach_function :pkgcraft_repo_ebuild_temp_create_ebuild_raw, [:pointer, :string, :string], :strptr

    # fake repo support
    attach_function :pkgcraft_repo_fake_new, [:string, :int, :pointer, :size_t], :pointer
    attach_function :pkgcraft_repo_fake_extend, [:repo, :pointer, :size_t], :repo

    # repo set support
    attach_function :pkgcraft_repo_set_repos, [RepoSet, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_repo_set_cmp, [RepoSet, RepoSet], :int
    attach_function :pkgcraft_repo_set_hash, [RepoSet], :uint64
    attach_function :pkgcraft_repo_set_iter, [RepoSet, Restrict], :pointer
    attach_function :pkgcraft_repo_set_iter_free, [:pointer], :void
    attach_function :pkgcraft_repo_set_iter_next, [:pointer], Pkg
    attach_function :pkgcraft_repo_set_len, [RepoSet], :uint64
    attach_function :pkgcraft_repo_set_is_empty, [RepoSet], :bool
    attach_function :pkgcraft_repo_set_new, [:pointer, :uint64], RepoSet
    attach_function :pkgcraft_repo_set_free, [:pointer], :void

    # pkg support
    attach_function :pkgcraft_pkg_format, [Pkg], :int
    attach_function :pkgcraft_pkg_free, [:pointer], :void
    attach_function :pkgcraft_pkg_cpv, [Pkg], Cpv
    attach_function :pkgcraft_pkg_eapi, [Pkg], :eapi
    attach_function :pkgcraft_pkg_repo, [Pkg], :pointer
    attach_function :pkgcraft_pkg_version, [Pkg], Version
    attach_function :pkgcraft_pkg_cmp, [Pkg, Pkg], :int
    attach_function :pkgcraft_pkg_hash, [Pkg], :uint64
    attach_function :pkgcraft_pkg_str, [Pkg], :strptr
    attach_function :pkgcraft_pkg_restrict, [Pkg], Restrict

    # ebuild pkg support
    attach_function :pkgcraft_pkg_ebuild_path, [Pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_ebuild, [Pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_description, [Pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_slot, [Pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_subslot, [Pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_long_description, [Pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_dependencies, [Pkg, :pointer, :size_t], :DepSet
    attach_function :pkgcraft_pkg_ebuild_depend, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_bdepend, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_idepend, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_pdepend, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_rdepend, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_license, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_properties, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_required_use, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_restrict, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_src_uri, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_defined_phases, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_homepage, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_keywords, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_iuse, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_inherit, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_inherited, [Pkg, LenPtr.by_ref], :pointer

    # dep_set support
    attach_function :pkgcraft_dep_set_eq, [:DepSet, :DepSet], :bool
    attach_function :pkgcraft_dep_set_hash, [:DepSet], :uint64
    attach_function :pkgcraft_dep_set_str, [:DepSet], :strptr
    attach_function :pkgcraft_dep_set_dependencies, [:string, :eapi], :DepSet
    attach_function :pkgcraft_dep_set_license, [:string], :DepSet
    attach_function :pkgcraft_dep_set_properties, [:string], :DepSet
    attach_function :pkgcraft_dep_set_required_use, [:string, :eapi], :DepSet
    attach_function :pkgcraft_dep_set_restrict, [:string], :DepSet
    attach_function :pkgcraft_dep_set_src_uri, [:string, :eapi], :DepSet
    attach_function :pkgcraft_dep_set_free, [:pointer], :void
    attach_function :pkgcraft_dep_set_into_iter, [:DepSet], :pointer
    attach_function :pkgcraft_dep_set_into_iter_next, [:pointer], :DepSpec
    attach_function :pkgcraft_dep_set_into_iter_free, [:pointer], :void
    attach_function :pkgcraft_dep_set_into_iter_flatten, [:DepSet], :pointer
    attach_function :pkgcraft_dep_set_into_iter_flatten_next, [:pointer], :pointer
    attach_function :pkgcraft_dep_set_into_iter_flatten_free, [:pointer], :void
    attach_function :pkgcraft_dep_set_into_iter_recursive, [:DepSet], :pointer
    attach_function :pkgcraft_dep_set_into_iter_recursive_next, [:pointer], :DepSpec
    attach_function :pkgcraft_dep_set_into_iter_recursive_free, [:pointer], :void

    # dep_spec support
    attach_function :pkgcraft_dep_spec_cmp, [:DepSpec, :DepSpec], :int
    attach_function :pkgcraft_dep_spec_hash, [:DepSpec], :uint64
    attach_function :pkgcraft_dep_spec_str, [:DepSpec], :strptr
    attach_function :pkgcraft_dep_spec_free, [:pointer], :void
    attach_function :pkgcraft_dep_spec_into_iter_flatten, [:DepSpec], :pointer
    attach_function :pkgcraft_dep_spec_into_iter_recursive, [:DepSpec], :pointer

    # URI dep_spec support
    attach_function :pkgcraft_uri_str, [:pointer], :strptr
    attach_function :pkgcraft_uri_free, [:pointer], :void

    # eapi support
    attach_function :pkgcraft_eapi_as_str, [:eapi], :strptr
    attach_function :pkgcraft_eapi_cmp, [:eapi, :eapi], :int
    attach_function :pkgcraft_eapi_has, [:eapi, :string], :bool
    attach_function :pkgcraft_eapi_hash, [:eapi], :uint64
    attach_function :pkgcraft_eapi_dep_keys, [:eapi, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_eapis_official, [LenPtr.by_ref], :pointer
    attach_function :pkgcraft_eapis, [LenPtr.by_ref], :pointer
    attach_function :pkgcraft_eapis_range, [:string, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_eapis_free, [:pointer, :size_t], :void

    # cpv support
    attach_function :pkgcraft_cpv_free, [:pointer], :void
    attach_function :pkgcraft_cpv_new, [:string], Cpv
    attach_function :pkgcraft_cpv_category, [Cpv], :strptr
    attach_function :pkgcraft_cpv_package, [Cpv], :strptr
    attach_function :pkgcraft_cpv_version, [Cpv], Version
    attach_function :pkgcraft_cpv_p, [Cpv], :strptr
    attach_function :pkgcraft_cpv_pf, [Cpv], :strptr
    attach_function :pkgcraft_cpv_pr, [Cpv], :strptr
    attach_function :pkgcraft_cpv_pv, [Cpv], :strptr
    attach_function :pkgcraft_cpv_pvr, [Cpv], :strptr
    attach_function :pkgcraft_cpv_cpn, [Cpv], :strptr
    attach_function :pkgcraft_cpv_intersects, [Cpv, Cpv], :bool
    attach_function :pkgcraft_cpv_intersects_dep, [Cpv, Dep], :bool
    attach_function :pkgcraft_cpv_hash, [Cpv], :uint64
    attach_function :pkgcraft_cpv_cmp, [Cpv, Cpv], :int
    attach_function :pkgcraft_cpv_str, [Cpv], :strptr
    attach_function :pkgcraft_cpv_restrict, [Cpv], Restrict

    # dep support
    attach_function :pkgcraft_dep_free, [:pointer], :void
    attach_function :pkgcraft_dep_new, [:string, :eapi], Dep
    attach_function :pkgcraft_dep_blocker, [Dep], :int
    attach_function :pkgcraft_dep_blocker_from_str, [:string], :int
    attach_function :pkgcraft_dep_category, [Dep], :strptr
    attach_function :pkgcraft_dep_package, [Dep], :strptr
    attach_function :pkgcraft_dep_version, [Dep], Version
    attach_function :pkgcraft_dep_slot, [Dep], :strptr
    attach_function :pkgcraft_dep_subslot, [Dep], :strptr
    attach_function :pkgcraft_dep_slot_op, [Dep], :int
    attach_function :pkgcraft_dep_slot_op_from_str, [:string], :int
    attach_function :pkgcraft_dep_use_deps, [Dep, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_dep_repo, [Dep], :strptr
    attach_function :pkgcraft_dep_p, [Dep], :strptr
    attach_function :pkgcraft_dep_pf, [Dep], :strptr
    attach_function :pkgcraft_dep_pr, [Dep], :strptr
    attach_function :pkgcraft_dep_pv, [Dep], :strptr
    attach_function :pkgcraft_dep_pvr, [Dep], :strptr
    attach_function :pkgcraft_dep_cpn, [Dep], :strptr
    attach_function :pkgcraft_dep_cpv, [Dep], :strptr
    attach_function :pkgcraft_dep_intersects, [Dep, Dep], :bool
    attach_function :pkgcraft_dep_intersects_cpv, [Dep, Cpv], :bool
    attach_function :pkgcraft_dep_hash, [Dep], :uint64
    attach_function :pkgcraft_dep_cmp, [Dep, Dep], :int
    attach_function :pkgcraft_dep_str, [Dep], :strptr
    attach_function :pkgcraft_dep_restrict, [Dep], Restrict

    # version support
    attach_function :pkgcraft_version_free, [:pointer], :void
    attach_function :pkgcraft_version_new, [:string], Version
    attach_function :pkgcraft_version_cmp, [Version, Version], :int
    attach_function :pkgcraft_version_hash, [Version], :uint64
    attach_function :pkgcraft_version_intersects, [Version, Version], :bool
    attach_function :pkgcraft_version_revision, [Version], :strptr
    attach_function :pkgcraft_version_op, [Version], :int
    attach_function :pkgcraft_version_op_from_str, [:string], :int
    attach_function :pkgcraft_version_str, [Version], :strptr
    attach_function :pkgcraft_version_str_with_op, [Version], :strptr
    attach_function :pkgcraft_version_with_op, [:string], Version

    # restriction support
    attach_function :pkgcraft_restrict_and, [Restrict, Restrict], Restrict
    attach_function :pkgcraft_restrict_or, [Restrict, Restrict], Restrict
    attach_function :pkgcraft_restrict_xor, [Restrict, Restrict], Restrict
    attach_function :pkgcraft_restrict_not, [Restrict], Restrict
    attach_function :pkgcraft_restrict_eq, [Restrict, Restrict], :bool
    attach_function :pkgcraft_restrict_hash, [Restrict], :uint64
    attach_function :pkgcraft_restrict_free, [:pointer], :void
    attach_function :pkgcraft_restrict_parse_dep, [:string], Restrict
    attach_function :pkgcraft_restrict_parse_pkg, [:string], Restrict
  end

  private_constant :C

  # Support outputting object ID for FFI::Pointer based objects.
  module InspectPointer
    def inspect
      "#<#{self.class} '#{self}' at 0x#{@ptr.address.to_s(16)}>"
    end
  end

  private_constant :InspectPointer

  # Support outputting object ID for FFI::Struct based objects.
  module InspectStruct
    def inspect
      "#<#{self.class} '#{self}' at 0x#{@ptr[:ptr].address.to_s(16)}>"
    end
  end

  private_constant :InspectStruct
end
