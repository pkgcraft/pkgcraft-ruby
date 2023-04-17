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

    # DepSet wrapper
    class DepSet < FFI::Struct
      layout :unit, :int,
             :kind, :int,
             :dep,  :pointer

      def self.release(ptr)
        C.pkgcraft_dep_set_free(ptr)
      end
    end

    # DepSpec wrapper
    class DepSpec < FFI::Struct
      layout :unit, :int,
             :kind, :int,
             :dep,  :pointer

      def self.release(ptr)
        C.pkgcraft_dep_spec_free(ptr)
      end
    end

    # error support
    class Error < FFI::Struct
      layout :message, :string,
             :kind, :int

      def self.release(ptr)
        C.pkgcraft_error_free(ptr)
      end
    end

    attach_function :pkgcraft_error_last, [], Error.auto_ptr
    attach_function :pkgcraft_error_free, [:pointer], :void

    # logging support
    class PkgcraftLog < FFI::Struct
      layout :message, :string,
             :level, :int
    end

    # Wrapper for config objects
    class Config < FFI::Struct
      layout :ptr, :pointer

      def self.release(ptr)
        C.pkgcraft_config_free(ptr)
      end
    end

    # Wrapper for Cpv objects
    class Cpv < FFI::Struct
      layout :ptr, :pointer

      def self.release(ptr)
        C.pkgcraft_cpv_free(ptr)
      end
    end

    # Wrapper for version objects
    class Version < FFI::Struct
      layout :ptr, :pointer

      def self.release(ptr)
        C.pkgcraft_version_free(ptr)
      end
    end

    # Wrapper for Dep objects
    class Dep < FFI::Struct
      layout :ptr, :pointer

      def self.release(ptr)
        C.pkgcraft_dep_free(ptr)
      end
    end

    # Wrapper for Restrict objects
    class Restrict < FFI::Struct
      layout :ptr, :pointer

      def self.release(ptr)
        C.pkgcraft_restrict_free(ptr)
      end
    end

    # Wrapper for Pkg objects
    class Pkg < FFI::Struct
      layout :ptr, :pointer

      def self.release(ptr)
        C.pkgcraft_pkg_free(ptr)
      end
    end

    # Wrapper for RepoSet objects
    class RepoSet < FFI::Struct
      layout :ptr, :pointer

      def self.release(ptr)
        C.pkgcraft_repo_set_free(ptr)
      end
    end

    # type aliases
    typedef Config.auto_ptr, :config
    typedef :pointer, :repo
    typedef RepoSet.auto_ptr, :repo_set
    typedef Pkg.auto_ptr, :pkg
    typedef :pointer, :eapi
    typedef Cpv.auto_ptr, :cpv
    typedef Dep.auto_ptr, :dep
    typedef DepSet.auto_ptr, :dep_set
    typedef DepSpec.auto_ptr, :dep_spec
    typedef Version.auto_ptr, :version
    typedef Restrict.auto_ptr, :restrict

    callback :log_callback, [PkgcraftLog.by_ref], :void
    attach_function :pkgcraft_logging_enable, [:log_callback], :void
    attach_function :pkgcraft_log_free, [PkgcraftLog.by_ref], :void
    attach_function :pkgcraft_log_test, [PkgcraftLog.by_ref], :void

    # config support
    attach_function :pkgcraft_config_new, [], :config
    attach_function :pkgcraft_config_free, [:pointer], :void
    attach_function :pkgcraft_config_load_repos_conf, [:config, :string, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_config_repos, [:config, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_config_repos_set, [:config, :int], :repo_set
    attach_function :pkgcraft_config_add_repo, [:config, :repo], :repo
    attach_function :pkgcraft_config_add_repo_path, [:config, :string, :int, :string], :repo

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
    attach_function :pkgcraft_repo_iter_next, [:pointer], :pkg
    attach_function :pkgcraft_repo_iter_restrict, [:repo, :restrict], :pointer
    attach_function :pkgcraft_repo_iter_restrict_free, [:repo], :void
    attach_function :pkgcraft_repo_iter_restrict_next, [:pointer], :pkg
    attach_function :pkgcraft_repo_format, [:repo], :int
    attach_function :pkgcraft_repo_free, [:repo], :void
    attach_function :pkgcraft_repo_from_path, [:string, :int, :string, :bool], :repo

    # ebuild repo support
    attach_function :pkgcraft_repo_ebuild_eapi, [:repo], :pointer
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
    attach_function :pkgcraft_repo_set_repos, [:repo_set, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_repo_set_cmp, [:repo_set, :repo_set], :int
    attach_function :pkgcraft_repo_set_hash, [:repo_set], :uint64
    attach_function :pkgcraft_repo_set_iter, [:repo_set, :restrict], :pointer
    attach_function :pkgcraft_repo_set_iter_free, [:pointer], :void
    attach_function :pkgcraft_repo_set_iter_next, [:pointer], :pkg
    attach_function :pkgcraft_repo_set_len, [:repo_set], :uint64
    attach_function :pkgcraft_repo_set_is_empty, [:repo_set], :bool
    attach_function :pkgcraft_repo_set_new, [:pointer, :uint64], :repo_set
    attach_function :pkgcraft_repo_set_free, [:pointer], :void

    # pkg support
    attach_function :pkgcraft_pkg_format, [:pkg], :int
    attach_function :pkgcraft_pkg_free, [:pointer], :void
    attach_function :pkgcraft_pkg_cpv, [:pkg], :cpv
    attach_function :pkgcraft_pkg_eapi, [:pkg], :pointer
    attach_function :pkgcraft_pkg_repo, [:pkg], :pointer
    attach_function :pkgcraft_pkg_version, [:pkg], :version
    attach_function :pkgcraft_pkg_cmp, [:pkg, :pkg], :int
    attach_function :pkgcraft_pkg_hash, [:pkg], :uint64
    attach_function :pkgcraft_pkg_str, [:pkg], :strptr
    attach_function :pkgcraft_pkg_restrict, [:pkg], :restrict

    # ebuild pkg support
    attach_function :pkgcraft_pkg_ebuild_path, [:pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_ebuild, [:pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_description, [:pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_slot, [:pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_subslot, [:pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_long_description, [:pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_dependencies, [:pkg, :pointer, :size_t], :dep_set
    attach_function :pkgcraft_pkg_ebuild_depend, [:pkg], :dep_set
    attach_function :pkgcraft_pkg_ebuild_bdepend, [:pkg], :dep_set
    attach_function :pkgcraft_pkg_ebuild_idepend, [:pkg], :dep_set
    attach_function :pkgcraft_pkg_ebuild_pdepend, [:pkg], :dep_set
    attach_function :pkgcraft_pkg_ebuild_rdepend, [:pkg], :dep_set
    attach_function :pkgcraft_pkg_ebuild_license, [:pkg], :dep_set
    attach_function :pkgcraft_pkg_ebuild_properties, [:pkg], :dep_set
    attach_function :pkgcraft_pkg_ebuild_required_use, [:pkg], :dep_set
    attach_function :pkgcraft_pkg_ebuild_restrict, [:pkg], :dep_set
    attach_function :pkgcraft_pkg_ebuild_src_uri, [:pkg], :dep_set

    # dep_set support
    attach_function :pkgcraft_dep_set_eq, [:dep_set, :dep_set], :bool
    attach_function :pkgcraft_dep_set_hash, [:dep_set], :uint64
    attach_function :pkgcraft_dep_set_str, [:dep_set], :strptr
    attach_function :pkgcraft_dep_set_dependencies, [:string, :eapi], :dep_set
    attach_function :pkgcraft_dep_set_license, [:string], :dep_set
    attach_function :pkgcraft_dep_set_properties, [:string], :dep_set
    attach_function :pkgcraft_dep_set_required_use, [:string, :eapi], :dep_set
    attach_function :pkgcraft_dep_set_restrict, [:string], :dep_set
    attach_function :pkgcraft_dep_set_src_uri, [:string, :eapi], :dep_set
    attach_function :pkgcraft_dep_set_free, [:pointer], :void
    attach_function :pkgcraft_dep_set_into_iter, [:dep_set], :pointer
    attach_function :pkgcraft_dep_set_into_iter_next, [:pointer], :dep_spec
    attach_function :pkgcraft_dep_set_into_iter_free, [:pointer], :void
    attach_function :pkgcraft_dep_set_into_iter_flatten, [:dep_set], :pointer
    attach_function :pkgcraft_dep_set_into_iter_flatten_next, [:pointer], :pointer
    attach_function :pkgcraft_dep_set_into_iter_flatten_free, [:pointer], :void
    attach_function :pkgcraft_dep_set_into_iter_recursive, [:dep_set], :pointer
    attach_function :pkgcraft_dep_set_into_iter_recursive_next, [:pointer], :dep_spec
    attach_function :pkgcraft_dep_set_into_iter_recursive_free, [:pointer], :void

    # dep_spec support
    attach_function :pkgcraft_dep_spec_cmp, [:dep_spec, :dep_spec], :int
    attach_function :pkgcraft_dep_spec_hash, [:dep_spec], :uint64
    attach_function :pkgcraft_dep_spec_str, [:dep_spec], :strptr
    attach_function :pkgcraft_dep_spec_free, [:pointer], :void
    attach_function :pkgcraft_dep_spec_into_iter_flatten, [:dep_spec], :pointer
    attach_function :pkgcraft_dep_spec_into_iter_recursive, [:dep_spec], :pointer

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
    attach_function :pkgcraft_cpv_new, [:string], :cpv
    attach_function :pkgcraft_cpv_category, [:cpv], :strptr
    attach_function :pkgcraft_cpv_package, [:cpv], :strptr
    attach_function :pkgcraft_cpv_version, [:cpv], :version
    attach_function :pkgcraft_cpv_p, [:cpv], :strptr
    attach_function :pkgcraft_cpv_pf, [:cpv], :strptr
    attach_function :pkgcraft_cpv_pr, [:cpv], :strptr
    attach_function :pkgcraft_cpv_pv, [:cpv], :strptr
    attach_function :pkgcraft_cpv_pvr, [:cpv], :strptr
    attach_function :pkgcraft_cpv_cpn, [:cpv], :strptr
    attach_function :pkgcraft_cpv_intersects, [:cpv, :cpv], :bool
    attach_function :pkgcraft_cpv_intersects_dep, [:cpv, :dep], :bool
    attach_function :pkgcraft_cpv_hash, [:cpv], :uint64
    attach_function :pkgcraft_cpv_cmp, [:cpv, :cpv], :int
    attach_function :pkgcraft_cpv_str, [:cpv], :strptr
    attach_function :pkgcraft_cpv_restrict, [:cpv], :restrict

    # dep support
    attach_function :pkgcraft_dep_free, [:pointer], :void
    attach_function :pkgcraft_dep_new, [:string, :eapi], :dep
    attach_function :pkgcraft_dep_blocker, [:dep], :int
    attach_function :pkgcraft_dep_blocker_from_str, [:string], :int
    attach_function :pkgcraft_dep_category, [:dep], :strptr
    attach_function :pkgcraft_dep_package, [:dep], :strptr
    attach_function :pkgcraft_dep_version, [:dep], :version
    attach_function :pkgcraft_dep_slot, [:dep], :strptr
    attach_function :pkgcraft_dep_subslot, [:dep], :strptr
    attach_function :pkgcraft_dep_slot_op, [:dep], :int
    attach_function :pkgcraft_dep_slot_op_from_str, [:string], :int
    attach_function :pkgcraft_dep_use_deps, [:dep, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_dep_repo, [:dep], :strptr
    attach_function :pkgcraft_dep_p, [:dep], :strptr
    attach_function :pkgcraft_dep_pf, [:dep], :strptr
    attach_function :pkgcraft_dep_pr, [:dep], :strptr
    attach_function :pkgcraft_dep_pv, [:dep], :strptr
    attach_function :pkgcraft_dep_pvr, [:dep], :strptr
    attach_function :pkgcraft_dep_cpn, [:dep], :strptr
    attach_function :pkgcraft_dep_cpv, [:dep], :strptr
    attach_function :pkgcraft_dep_intersects, [:dep, :dep], :bool
    attach_function :pkgcraft_dep_intersects_cpv, [:dep, :cpv], :bool
    attach_function :pkgcraft_dep_hash, [:dep], :uint64
    attach_function :pkgcraft_dep_cmp, [:dep, :dep], :int
    attach_function :pkgcraft_dep_str, [:dep], :strptr
    attach_function :pkgcraft_dep_restrict, [:dep], :restrict

    # version support
    attach_function :pkgcraft_version_free, [:pointer], :void
    attach_function :pkgcraft_version_new, [:string], :version
    attach_function :pkgcraft_version_cmp, [:version, :version], :int
    attach_function :pkgcraft_version_hash, [:version], :uint64
    attach_function :pkgcraft_version_intersects, [:version, :version], :bool
    attach_function :pkgcraft_version_revision, [:version], :strptr
    attach_function :pkgcraft_version_op, [:version], :int
    attach_function :pkgcraft_version_op_from_str, [:string], :int
    attach_function :pkgcraft_version_str, [:version], :strptr
    attach_function :pkgcraft_version_str_with_op, [:version], :strptr
    attach_function :pkgcraft_version_with_op, [:string], :version

    # restriction support
    attach_function :pkgcraft_restrict_and, [:restrict, :restrict], :restrict
    attach_function :pkgcraft_restrict_or, [:restrict, :restrict], :restrict
    attach_function :pkgcraft_restrict_xor, [:restrict, :restrict], :restrict
    attach_function :pkgcraft_restrict_not, [:restrict], :restrict
    attach_function :pkgcraft_restrict_eq, [:restrict, :restrict], :bool
    attach_function :pkgcraft_restrict_hash, [:restrict], :uint64
    attach_function :pkgcraft_restrict_free, [:pointer], :void
    attach_function :pkgcraft_restrict_parse_dep, [:string], :restrict
    attach_function :pkgcraft_restrict_parse_pkg, [:string], :restrict
  end
end
