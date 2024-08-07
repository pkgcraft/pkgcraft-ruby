# frozen_string_literal: true

require "ffi"

module Pkgcraft
  # FFI bindings for pkgcraft
  module C
    # version requirements for pkgcraft-c
    MIN_VERSION = "0.0.17"
    MAX_VERSION = "0.0.17"

    extend FFI::Library
    ffi_lib ["pkgcraft"]

    # generic free support
    attach_function :pkgcraft_array_free, [:pointer, :size_t], :void
    attach_function :pkgcraft_str_array_free, [:pointer, :size_t], :void
    attach_function :pkgcraft_str_free, [:pointer], :void

    # array length pointer for working with array return values
    class LenPtr < FFI::Struct
      layout :value, :size_t
    end

    # Pointer-based object conversion support.
    module PointerConversion
      def to_native(value, _context = nil)
        return value.instance_variable_get(:@ptr) if value.is_a?(self)

        raise TypeError.new("expected a kind of #{name}, was #{value.class}")
      end

      def from_native(value, _context = nil)
        # convert nil values to proper null pointer objects
        value = FFI::Pointer.new(0) if value.nil?

        obj = allocate
        superclass.instance_method(:initialize).bind(obj).call(value)
        obj.instance_variable_set(:@ptr, value)
        obj
      end
    end

    # Wrapper for pointer-based objects that will be garbage-collected.
    class AutoPointer < FFI::AutoPointer
      extend PointerConversion
    end

    # Wrapper for pointer-based objects that aren't released.
    class Pointer < FFI::Pointer
      extend FFI::DataConverter
      extend PointerConversion

      def self.native_type
        FFI::Type::POINTER
      end
    end

    # Wrapper for string pointers.
    class String
      extend FFI::DataConverter
      native_type FFI::Type::POINTER

      class << self
        def from_native(value, _context = nil)
          # return nil for null pointers
          return if value.null?

          s = value.read_string
          C.pkgcraft_str_free(value)
          s
        end
      end
    end

    # Convert a char** to an array of String objects.
    def self.ptr_to_string_array(func, *args)
      length = C::LenPtr.new
      ptr = func.call(*args, length)
      return if ptr.null?

      value = ptr.get_array_of_string(0, length[:value])
      C.pkgcraft_str_array_free(ptr, length[:value])
      value
    end

    # Convert an enumerable object of string convertible objects to a char**.
    def self.string_iter_to_ptr(iterable)
      strs = iterable.collect(&:to_s)
      ptr = FFI::MemoryPointer.new(:pointer, strs.length)
      ptr.write_array_of_pointer(strs.map { |s| FFI::MemoryPointer.from_string(s) })
      [ptr, strs.length]
    end

    # Convert an array of pointers to their respective Ruby objects.
    def self.ptr_to_obj_array(obj_cls, func, *args)
      length = C::LenPtr.new
      ptr = func.call(*args, length)
      return if ptr.null?

      objs = ptr.get_array_of_pointer(0, length[:value])
      objs = objs.map { |p| obj_cls.from_native(p) }
      C.pkgcraft_array_free(ptr, length[:value])
      objs
    end

    # Return the pkgcraft-c library version.
    def self.version
      attach_function :pkgcraft_lib_version, [], String
      version = Gem::Version.new(pkgcraft_lib_version)

      # verify version requirements for pkgcraft C library
      minver = Gem::Version.new(MIN_VERSION)
      maxver = Gem::Version.new(MAX_VERSION)
      raise "pkgcraft C library #{version} fails requirement >=#{minver}" if version < minver
      raise "pkgcraft C library #{version} fails requirement <=#{maxver}" if version > maxver

      version
    end

    private_class_method :version

    # Version of the pkgcraft-c library.
    VERSION = version.freeze
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
