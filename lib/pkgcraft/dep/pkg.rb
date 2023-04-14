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
    class Dep
      include Comparable
      include Eapis
      attr_reader :ptr

      def initialize(str, eapi = EAPI_LATEST)
        eapi = Eapi.from_obj(eapi) unless eapi.nil?
        ptr = C.pkgcraft_dep_new(str.to_s, eapi.ptr)
        raise Error::InvalidDep if ptr.null?

        self.ptr = ptr
      end

      # Create a Dep from a pointer.
      def self.from_ptr(ptr)
        obj = allocate
        obj.send(:ptr=, ptr)
        obj
      end

      private_class_method :from_ptr

      def blocker
        val = C.pkgcraft_dep_blocker(@ptr)
        return Blocker[val] unless val.zero?
      end

      def category
        @_category, ptr = C.pkgcraft_dep_category(@ptr) if @_category.nil?
        C.pkgcraft_str_free(ptr)
        @_category
      end

      def package
        @_package, ptr = C.pkgcraft_dep_package(@ptr) if @_package.nil?
        C.pkgcraft_str_free(ptr)
        @_package
      end

      def version
        @_version = Version.send(:from_ptr, C.pkgcraft_dep_version(@ptr)) if @_version.nil?
        @_version
      end

      def revision
        return version.revision unless version.nil?
      end

      def op
        return version.op unless version.nil?
      end

      def slot
        s, ptr = C.pkgcraft_dep_slot(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def subslot
        s, ptr = C.pkgcraft_dep_subslot(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def slot_op
        val = C.pkgcraft_dep_slot_op(@ptr)
        return SlotOperator[val] unless val.zero?
      end

      def use
        length = C::LenPtr.new
        ptr = C.pkgcraft_dep_use_deps(@ptr, length)
        return if ptr.null?

        use = ptr.get_array_of_string(0, length[:value])
        C.pkgcraft_str_array_free(ptr, length[:value])
        use
      end

      def repo
        s, ptr = C.pkgcraft_dep_repo(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def p
        s, ptr = C.pkgcraft_dep_p(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def pf
        s, ptr = C.pkgcraft_dep_pf(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def pr
        s, ptr = C.pkgcraft_dep_pr(@ptr)
        return if ptr.null?

        C.pkgcraft_str_free(ptr)
        s
      end

      def pv
        s, ptr = C.pkgcraft_dep_pv(@ptr)
        return if ptr.null?

        C.pkgcraft_str_free(ptr)
        s
      end

      def pvr
        s, ptr = C.pkgcraft_dep_pvr(@ptr)
        return if ptr.null?

        C.pkgcraft_str_free(ptr)
        s
      end

      def cpn
        s, ptr = C.pkgcraft_dep_cpn(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def cpv
        s, ptr = C.pkgcraft_dep_cpv(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def intersects(other)
        return C.pkgcraft_dep_intersects(@ptr, other.ptr) if other.is_a? Dep

        return C.pkgcraft_dep_intersects_cpv(@ptr, other.ptr) if other.is_a? Cpv

        raise TypeError.new("Invalid type: #{other.class}")
      end

      def to_s
        s, ptr = C.pkgcraft_dep_str(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def <=>(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? Dep

        C.pkgcraft_dep_cmp(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        @_hash = C.pkgcraft_dep_hash(@ptr) if @_hash.nil?
        @_hash
      end

      private

      def ptr=(ptr)
        @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_dep_free))
      end
    end
  end
end
