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

    # Wrapper for pointer-based objects.
    class AutoPointer < FFI::AutoPointer
      class << self
        def to_native(value, _context)
          return value.instance_variable_get(:@ptr) if value.is_a?(self)

          raise TypeError.new("expected a kind of #{name}, was #{value.class}")
        end

        def from_native(value, _context)
          obj = allocate
          FFI::AutoPointer.instance_method(:initialize).bind(obj).call(value)
          obj.instance_variable_set(:@ptr, value)
          obj
        end
      end
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

    # Wrapper for version objects
    class Version < FFI::AutoPointer
      def self.release(ptr)
        C.pkgcraft_version_free(ptr)
      end
    end

    # Wrapper for Restrict objects
    class Restrict < FFI::AutoPointer
      def self.release(ptr)
        C.pkgcraft_restrict_free(ptr)
      end
    end

    # type aliases
    typedef :pointer, :eapi
    typedef DepSet.by_ref, :DepSet
    typedef DepSpec.by_ref, :DepSpec

    callback :log_callback, [PkgcraftLog.by_ref], :void
    attach_function :pkgcraft_logging_enable, [:log_callback], :void
    attach_function :pkgcraft_log_free, [:pointer], :void
    attach_function :pkgcraft_log_test, [PkgcraftLog.by_ref], :void

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
      "#<#{self.class} at 0x#{@ptr.address.to_s(16)}>"
    end
  end

  private_constant :InspectPointer

  # Support outputting object ID for FFI::Pointer based objects that can render
  # to a human-readable string.
  module InspectPointerRender
    def inspect
      "#<#{self.class} '#{self}' at 0x#{@ptr.address.to_s(16)}>"
    end
  end

  private_constant :InspectPointerRender

  # Support outputting object ID for FFI::Struct based objects.
  module InspectStruct
    def inspect
      "#<#{self.class} '#{self}' at 0x#{@ptr[:ptr].address.to_s(16)}>"
    end
  end

  private_constant :InspectStruct
end
