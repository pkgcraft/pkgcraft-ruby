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
        @ptr = C.pkgcraft_dep_new(str.to_s, eapi)
        @version = SENTINEL
        raise Error::InvalidDep if @ptr.null?
      end

      def blocker
        val = C.pkgcraft_dep_blocker(self)
        return Blocker[val] unless val.zero?
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
        C.pkgcraft_dep_slot(self)
      end

      def subslot
        C.pkgcraft_dep_subslot(self)
      end

      def slot_op
        val = C.pkgcraft_dep_slot_op(self)
        return SlotOperator[val] unless val.zero?
      end

      def use
        C.ptr_to_string_array(C.method(:pkgcraft_dep_use_deps), self)
      end

      def repo
        C.pkgcraft_dep_repo(self)
      end

      def p
        C.pkgcraft_dep_p(self)
      end

      def pf
        C.pkgcraft_dep_pf(self)
      end

      def pr
        C.pkgcraft_dep_pr(self)
      end

      def pv
        C.pkgcraft_dep_pv(self)
      end

      def pvr
        C.pkgcraft_dep_pvr(self)
      end

      def cpn
        C.pkgcraft_dep_cpn(self)
      end

      def cpv
        C.pkgcraft_dep_cpv(self)
      end

      def intersects(other)
        return C.pkgcraft_dep_intersects(self, other) if other.is_a? Dep

        return C.pkgcraft_dep_intersects_cpv(self, other) if other.is_a? Cpv

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

    # Unversioned package dependency
    class Cpn < Dep
      def initialize(str)
        @ptr = C.pkgcraft_dep_new_cpn(str.to_s)
        raise Error::InvalidDep if @ptr.null?
      end
    end
  end
end
