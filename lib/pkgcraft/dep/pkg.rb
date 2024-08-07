# frozen_string_literal: true

module Pkgcraft
  module Dep
    # Dependency blocker
    class Blocker
      extend FFI::Library

      @enum = enum(
        :Strong, 1,
        :Weak
      )

      def self.[](val)
        val = @enum[val]
        return val unless val.nil?

        raise "unknown value: #{val}"
      end

      def self.from_str(str)
        val = C.pkgcraft_dep_blocker_from_str(str.to_s)
        return @enum[val] unless val.zero?

        raise "unknown value: #{val}"
      end

      def self.const_missing(symbol)
        # look up symbol as an enum
        value = enum_value(symbol)

        # if nonexistent, raise an exception via the default behavior
        return super unless value

        @enum[value]
      end
    end

    # Slot operator
    class SlotOperator
      extend FFI::Library

      @enum = enum(
        :Equal, 1,
        :Star
      )

      def self.[](val)
        val = @enum[val]
        return val unless val.nil?

        raise "unknown value: #{val}"
      end

      def self.from_str(str)
        val = C.pkgcraft_dep_slot_op_from_str(str.to_s)
        return @enum[val] unless val.zero?

        raise "unknown value: #{val}"
      end

      def self.const_missing(symbol)
        # look up symbol as an enum
        value = enum_value(symbol)

        # if nonexistent, raise an exception via the default behavior
        return super unless value

        @enum[value]
      end
    end

    # Package dependency
    class Dep < C::Dep
      include InspectPointerRender
      include Pkgcraft::Eapis
      include Comparable

      # Create a Dep from a pointer.
      def self.from_ptr(ptr)
        obj = allocate
        obj.instance_variable_set(:@ptr, ptr)
        obj.instance_variable_set(:@Version, SENTINEL)
        obj
      end

      private_class_method :from_ptr

      def initialize(str, eapi = EAPI_LATEST)
        eapi = Eapi.from_obj(eapi)
        @ptr = C.pkgcraft_dep_new(str.to_s, eapi)
        @version = SENTINEL
        raise Error::InvalidDep if @ptr.null?
      end

      def self.parse(str, eapi = nil, raised: false)
        eapi = Eapi.from_obj(eapi)
        valid = !C.pkgcraft_dep_parse(str.to_s, eapi).null?
        raise Error::InvalidDep if !valid && raised

        valid
      end

      def blocker
        val = C.pkgcraft_dep_blocker(self)
        Blocker[val] unless val.zero?
      end

      def category
        @category = C.pkgcraft_dep_category(self) if @category.nil?
        @category
      end

      def package
        @package = C.pkgcraft_dep_package(self) if @package.nil?
        @package
      end

      def version
        if @version.equal?(SENTINEL)
          ptr = C.pkgcraft_dep_version(self)
          @version = ptr.null? ? nil : Version.send(:from_ptr, ptr)
        end
        @version
      end

      def revision
        version&.revision
      end

      def op
        version&.op
      end

      def slot
        C.pkgcraft_dep_slot(self)
      end

      def subslot
        C.pkgcraft_dep_subslot(self)
      end

      def slot_op
        val = C.pkgcraft_dep_slot_op(self)
        SlotOperator[val] unless val.zero?
      end

      def use
        C.ptr_to_string_array(C.method(:pkgcraft_dep_use_deps_str), self)
      end

      def repo
        C.pkgcraft_dep_repo(self)
      end

      def cpn
        ptr = C.pkgcraft_dep_cpn(self)
        Cpn.send(:from_ptr, ptr)
      end

      def cpv
        ptr = C.pkgcraft_dep_cpv(self)
        ptr.null? ? nil : Cpv.send(:from_ptr, ptr)
      end

      def unversioned
        ptr = C.pkgcraft_dep_unversioned(self)
        return Dep.send(:from_ptr, ptr) if ptr != @ptr

        self
      end

      def versioned
        ptr = C.pkgcraft_dep_versioned(self)
        return Dep.send(:from_ptr, ptr) if ptr != @ptr

        self
      end

      def no_use_deps
        ptr = C.pkgcraft_dep_no_use_deps(self)
        return Dep.send(:from_ptr, ptr) if ptr != @ptr

        self
      end

      def intersects(other)
        return C.pkgcraft_dep_intersects(self, other) if other.is_a? Dep
        return C.pkgcraft_dep_intersects_cpv(self, other) if other.is_a? Cpv
        return C.pkgcraft_pkg_intersects_dep(other, self) if other.is_a? Pkgcraft::Pkgs::Pkg

        raise TypeError.new("Invalid type: #{other.class}")
      end

      def to_s
        C.pkgcraft_dep_str(self)
      end

      def <=>(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? Dep

        C.pkgcraft_dep_cmp(self, other)
      end

      alias eql? ==

      def hash
        @hash = C.pkgcraft_dep_hash(self) if @hash.nil?
        @hash
      end
    end
  end

  # FFI bindings for Dep related functionality
  module C
    attach_function :pkgcraft_dep_blocker, [Dep], :int
    attach_function :pkgcraft_dep_blocker_from_str, [:string], :int
    attach_function :pkgcraft_dep_category, [Dep], String
    attach_function :pkgcraft_dep_cmp, [Dep, Dep], :int
    attach_function :pkgcraft_dep_cpn, [Dep], Cpn
    attach_function :pkgcraft_dep_cpv, [Dep], Cpv
    attach_function :pkgcraft_dep_free, [:pointer], :void
    attach_function :pkgcraft_dep_hash, [Dep], :uint64
    attach_function :pkgcraft_dep_intersects, [Dep, Dep], :bool
    attach_function :pkgcraft_dep_intersects_cpv, [Dep, Cpv], :bool
    attach_function :pkgcraft_dep_new, [:string, Eapi], Dep
    attach_function :pkgcraft_dep_no_use_deps, [Dep], :pointer
    attach_function :pkgcraft_dep_package, [Dep], String
    attach_function :pkgcraft_dep_parse, [:string, Eapi], :pointer
    attach_function :pkgcraft_dep_repo, [Dep], String
    attach_function :pkgcraft_dep_restrict, [Dep], Restrict
    attach_function :pkgcraft_dep_slot, [Dep], String
    attach_function :pkgcraft_dep_slot_op, [Dep], :int
    attach_function :pkgcraft_dep_slot_op_from_str, [:string], :int
    attach_function :pkgcraft_dep_str, [Dep], String
    attach_function :pkgcraft_dep_subslot, [Dep], String
    attach_function :pkgcraft_dep_unversioned, [Dep], :pointer
    attach_function :pkgcraft_dep_use_deps_str, [Dep, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_dep_version, [Dep], Version
    attach_function :pkgcraft_dep_versioned, [Dep], :pointer
  end
end
