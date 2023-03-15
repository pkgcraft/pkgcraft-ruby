# frozen_string_literal: true

module Pkgcraft
  module Dep
    # Package dependency
    class Dep
      include Comparable
      attr_reader :ptr

      def initialize(str, eapi = Pkgcraft::Eapi.latest)
        eapi = Eapi.from_obj(eapi) unless eapi.nil?
        ptr = C.pkgcraft_dep_new(str, eapi.ptr)
        raise InvalidDep if ptr.null?

        self.ptr = ptr
      end

      def self.from_ptr(ptr)
        obj = allocate
        obj.send(:ptr=, ptr)
        obj
      end

      def category
        s, ptr = C.pkgcraft_dep_category(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def package
        s, ptr = C.pkgcraft_dep_package(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def version
        @_version = Version.from_ptr(C.pkgcraft_dep_version(@ptr)) if @_version.nil?

        @_version
      end

      def revision
        return if version.nil?

        version.revision
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
