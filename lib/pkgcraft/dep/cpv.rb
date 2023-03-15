# frozen_string_literal: true

module Pkgcraft
  module Dep
    # CPV object support (category/package-version)
    class Cpv
      include Comparable
      attr_reader :ptr

      def initialize(str)
        ptr = C.pkgcraft_cpv_new(str)
        raise Error::InvalidCpv if ptr.null?

        self.ptr = ptr
      end

      def self.from_ptr(ptr)
        obj = allocate
        obj.send(:ptr=, ptr)
        obj
      end

      def category
        s, ptr = C.pkgcraft_cpv_category(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def package
        s, ptr = C.pkgcraft_cpv_package(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def version
        @_version = Version.from_ptr(C.pkgcraft_cpv_version(@ptr)) if @_version.nil?

        @_version
      end

      def revision
        version.revision
      end

      def p
        s, ptr = C.pkgcraft_cpv_p(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def pf
        s, ptr = C.pkgcraft_cpv_pf(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def pr
        s, ptr = C.pkgcraft_cpv_pr(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def pv
        s, ptr = C.pkgcraft_cpv_pv(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def pvr
        s, ptr = C.pkgcraft_cpv_pvr(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def cpn
        s, ptr = C.pkgcraft_cpv_cpn(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def intersects(other)
        return C.pkgcraft_cpv_intersects(@ptr, other.ptr) if other.is_a? Cpv

        return C.pkgcraft_cpv_intersects_dep(@ptr, other.ptr) if other.is_a? Dep

        raise TypeError.new("invalid type: #{other.class}")
      end

      def to_s
        s, ptr = C.pkgcraft_cpv_str(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def <=>(other)
        C.pkgcraft_cpv_cmp(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        @_hash = C.pkgcraft_cpv_hash(@ptr) if @_hash.nil?

        @_hash
      end

      private

      def ptr=(ptr)
        @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_cpv_free))
      end
    end
  end
end
