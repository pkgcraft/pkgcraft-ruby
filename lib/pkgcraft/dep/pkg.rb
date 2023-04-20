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

      def initialize(str, eapi = EAPI_LATEST)
        eapi = Eapi.from_obj(eapi)
        @ptr = C.pkgcraft_dep_new(str.to_s, eapi.ptr)
        @version = SENTINEL
        raise Error::InvalidDep if @ptr.null?
      end

      def blocker
        val = C.pkgcraft_dep_blocker(self)
        return Blocker[val] unless val.zero?
      end

      def category
        @category, ptr = C.pkgcraft_dep_category(self) if @category.nil?
        C.pkgcraft_str_free(ptr)
        @category
      end

      def package
        @package, ptr = C.pkgcraft_dep_package(self) if @package.nil?
        C.pkgcraft_str_free(ptr)
        @package
      end

      def version
        if @version.equal?(SENTINEL)
          @version = C.pkgcraft_dep_version(self)
          @version = nil if @version.null?
        end
        @version
      end

      def revision
        return version.revision unless version.nil?
      end

      def op
        return version.op unless version.nil?
      end

      def slot
        s, ptr = C.pkgcraft_dep_slot(self)
        C.pkgcraft_str_free(ptr)
        s
      end

      def subslot
        s, ptr = C.pkgcraft_dep_subslot(self)
        C.pkgcraft_str_free(ptr)
        s
      end

      def slot_op
        val = C.pkgcraft_dep_slot_op(self)
        return SlotOperator[val] unless val.zero?
      end

      def use
        length = C::LenPtr.new
        ptr = C.pkgcraft_dep_use_deps(self, length)
        return if ptr.null?

        use = ptr.get_array_of_string(0, length[:value])
        C.pkgcraft_str_array_free(ptr, length[:value])
        use
      end

      def repo
        s, ptr = C.pkgcraft_dep_repo(self)
        C.pkgcraft_str_free(ptr)
        s
      end

      def p
        s, ptr = C.pkgcraft_dep_p(self)
        C.pkgcraft_str_free(ptr)
        s
      end

      def pf
        s, ptr = C.pkgcraft_dep_pf(self)
        C.pkgcraft_str_free(ptr)
        s
      end

      def pr
        s, ptr = C.pkgcraft_dep_pr(self)
        return if ptr.null?

        C.pkgcraft_str_free(ptr)
        s
      end

      def pv
        s, ptr = C.pkgcraft_dep_pv(self)
        return if ptr.null?

        C.pkgcraft_str_free(ptr)
        s
      end

      def pvr
        s, ptr = C.pkgcraft_dep_pvr(self)
        return if ptr.null?

        C.pkgcraft_str_free(ptr)
        s
      end

      def cpn
        s, ptr = C.pkgcraft_dep_cpn(self)
        C.pkgcraft_str_free(ptr)
        s
      end

      def cpv
        s, ptr = C.pkgcraft_dep_cpv(self)
        C.pkgcraft_str_free(ptr)
        s
      end

      def intersects(other)
        return C.pkgcraft_dep_intersects(self, other) if other.is_a? Dep

        return C.pkgcraft_dep_intersects_cpv(self, other) if other.is_a? Cpv

        raise TypeError.new("Invalid type: #{other.class}")
      end

      def to_s
        s, ptr = C.pkgcraft_dep_str(self)
        C.pkgcraft_str_free(ptr)
        s
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
end
