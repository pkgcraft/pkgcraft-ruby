# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for Dep related functionality
  module C
    # Wrapper for Cpn pointers
    class Cpn < AutoPointer
      def self.release(ptr)
        C.pkgcraft_cpn_free(ptr)
      end
    end

    # Wrapper for Cpv pointers
    class Cpv < AutoPointer
      def self.release(ptr)
        C.pkgcraft_cpv_free(ptr)
      end
    end

    # Wrapper for Dep pointers
    class Dep < AutoPointer
      def self.release(ptr)
        C.pkgcraft_dep_free(ptr)
      end
    end

    # Wrapper for version pointers
    class Version < AutoPointer
      def self.release(ptr)
        C.pkgcraft_version_free(ptr)
      end
    end

    # Wrapper for revision pointers
    class Revision < AutoPointer
      def self.release(ptr)
        C.pkgcraft_revision_free(ptr)
      end
    end
  end
end

require_relative "dep/cpn"
require_relative "dep/cpv"
require_relative "dep/pkg"
require_relative "dep/base"
require_relative "dep/version"

module Pkgcraft
  # FFI bindings for Dep related functionality
  module C
    # cpn support
    attach_function :pkgcraft_cpn_free, [:pointer], :void
    attach_function :pkgcraft_cpn_new, [:string], Cpn
    attach_function :pkgcraft_cpn_category, [Cpn], String
    attach_function :pkgcraft_cpn_package, [Cpn], String
    attach_function :pkgcraft_cpn_hash, [Cpn], :uint64
    attach_function :pkgcraft_cpn_cmp, [Cpn, Cpn], :int
    attach_function :pkgcraft_cpn_str, [Cpn], String

    # cpv support
    attach_function :pkgcraft_cpv_free, [:pointer], :void
    attach_function :pkgcraft_cpv_new, [:string], Cpv
    attach_function :pkgcraft_cpv_category, [Cpv], String
    attach_function :pkgcraft_cpv_package, [Cpv], String
    attach_function :pkgcraft_cpv_version, [Cpv], Pkgcraft::Dep::Version
    attach_function :pkgcraft_cpv_p, [Cpv], String
    attach_function :pkgcraft_cpv_pf, [Cpv], String
    attach_function :pkgcraft_cpv_pr, [Cpv], String
    attach_function :pkgcraft_cpv_pv, [Cpv], String
    attach_function :pkgcraft_cpv_pvr, [Cpv], String
    attach_function :pkgcraft_cpv_cpn, [Cpv], Pkgcraft::Dep::Cpn
    attach_function :pkgcraft_cpv_intersects, [Cpv, Cpv], :bool
    attach_function :pkgcraft_cpv_intersects_dep, [Cpv, Dep], :bool
    attach_function :pkgcraft_cpv_hash, [Cpv], :uint64
    attach_function :pkgcraft_cpv_cmp, [Cpv, Cpv], :int
    attach_function :pkgcraft_cpv_str, [Cpv], String
    attach_function :pkgcraft_cpv_restrict, [Cpv], Restrict

    # dep support
    attach_function :pkgcraft_dep_free, [:pointer], :void
    attach_function :pkgcraft_dep_new, [:string, Eapi], Dep
    attach_function :pkgcraft_dep_blocker, [Dep], :int
    attach_function :pkgcraft_dep_blocker_from_str, [:string], :int
    attach_function :pkgcraft_dep_category, [Dep], String
    attach_function :pkgcraft_dep_package, [Dep], String
    attach_function :pkgcraft_dep_version, [Dep], Pkgcraft::Dep::Version
    attach_function :pkgcraft_dep_slot, [Dep], String
    attach_function :pkgcraft_dep_subslot, [Dep], String
    attach_function :pkgcraft_dep_slot_op, [Dep], :int
    attach_function :pkgcraft_dep_slot_op_from_str, [:string], :int
    attach_function :pkgcraft_dep_use_deps_str, [Dep, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_dep_repo, [Dep], String
    attach_function :pkgcraft_dep_p, [Dep], String
    attach_function :pkgcraft_dep_pf, [Dep], String
    attach_function :pkgcraft_dep_pr, [Dep], String
    attach_function :pkgcraft_dep_pv, [Dep], String
    attach_function :pkgcraft_dep_pvr, [Dep], String
    attach_function :pkgcraft_dep_cpn, [Dep], Pkgcraft::Dep::Cpn
    attach_function :pkgcraft_dep_cpv, [Dep], String
    attach_function :pkgcraft_dep_intersects, [Dep, Dep], :bool
    attach_function :pkgcraft_dep_intersects_cpv, [Dep, Cpv], :bool
    attach_function :pkgcraft_dep_hash, [Dep], :uint64
    attach_function :pkgcraft_dep_cmp, [Dep, Dep], :int
    attach_function :pkgcraft_dep_str, [Dep], String
    attach_function :pkgcraft_dep_restrict, [Dep], Restrict
    attach_function :pkgcraft_dep_parse, [:string, Eapi], :pointer

    # version support
    attach_function :pkgcraft_version_free, [:pointer], :void
    attach_function :pkgcraft_version_new, [:string], Version
    attach_function :pkgcraft_version_cmp, [Version, Version], :int
    attach_function :pkgcraft_version_hash, [Version], :uint64
    attach_function :pkgcraft_version_intersects, [Version, Version], :bool
    attach_function :pkgcraft_version_revision, [Version], Pkgcraft::Dep::Revision
    attach_function :pkgcraft_version_op, [Version], :int
    attach_function :pkgcraft_version_op_from_str, [:string], :int
    attach_function :pkgcraft_version_str, [Version], String
    attach_function :pkgcraft_version_parse, [:string], :pointer

    # revision support
    attach_function :pkgcraft_revision_free, [:pointer], :void
    attach_function :pkgcraft_revision_new, [:string], Revision
    attach_function :pkgcraft_revision_cmp, [Revision, Revision], :int
    attach_function :pkgcraft_revision_hash, [Revision], :uint64
    attach_function :pkgcraft_revision_str, [Revision], String
  end
end
