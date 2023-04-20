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
      attach_function :pkgcraft_lib_version, [], :strptr

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
        def to_native(value, _context = nil)
          return value.instance_variable_get(:@ptr) if value.is_a?(self)

          raise TypeError.new("expected a kind of #{name}, was #{value.class}")
        end

        def from_native(value, _context = nil)
          # convert nil values to proper null pointer objects
          value = FFI::Pointer.new(0) if value.nil?

          obj = allocate
          FFI::AutoPointer.instance_method(:initialize).bind(obj).call(value)
          obj.instance_variable_set(:@ptr, value)
          obj
        end
      end
    end

    # type aliases
    typedef :pointer, :eapi

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
