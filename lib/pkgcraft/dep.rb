# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for Dep related functionality
  module C
    # Wrapper for Cpv pointers
    class Cpv < AutoPointer
      def self.release(ptr)
        C.pkgcraft_cpv_free(ptr)
      end
    end

    # Wrapper for Dep objects
    class Dep < AutoPointer
      def self.release(ptr)
        C.pkgcraft_dep_free(ptr)
      end
    end

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
  end
end

require_relative "dep/cpv"
require_relative "dep/pkg"
require_relative "dep/set"
require_relative "dep/spec"
require_relative "dep/version"
