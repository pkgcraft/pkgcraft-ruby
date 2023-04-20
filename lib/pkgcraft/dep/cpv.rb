# frozen_string_literal: true

module Pkgcraft
  module Dep
    # CPV object support (category/package-version)
    class Cpv < C::Cpv
      include InspectPointerRender
      include Comparable

      def initialize(str)
        @ptr = C.pkgcraft_cpv_new(str.to_s)
        raise Error::InvalidCpv if @ptr.null?
      end

      def category
        @category, ptr = C.pkgcraft_cpv_category(self) if @category.nil?
        C.pkgcraft_str_free(ptr)
        @category
      end

      def package
        @package, ptr = C.pkgcraft_cpv_package(self) if @package.nil?
        C.pkgcraft_str_free(ptr)
        @package
      end

      def version
        @version = Version.send(:from_ptr, C.pkgcraft_cpv_version(self)) if @version.nil?
        @version
      end

      def revision
        version.revision
      end

      def p
        s, ptr = C.pkgcraft_cpv_p(self)
        C.pkgcraft_str_free(ptr)
        s
      end

      def pf
        s, ptr = C.pkgcraft_cpv_pf(self)
        C.pkgcraft_str_free(ptr)
        s
      end

      def pr
        s, ptr = C.pkgcraft_cpv_pr(self)
        C.pkgcraft_str_free(ptr)
        s
      end

      def pv
        s, ptr = C.pkgcraft_cpv_pv(self)
        C.pkgcraft_str_free(ptr)
        s
      end

      def pvr
        s, ptr = C.pkgcraft_cpv_pvr(self)
        C.pkgcraft_str_free(ptr)
        s
      end

      def cpn
        s, ptr = C.pkgcraft_cpv_cpn(self)
        C.pkgcraft_str_free(ptr)
        s
      end

      def intersects(other)
        return C.pkgcraft_cpv_intersects(self, other) if other.is_a? Cpv

        return C.pkgcraft_cpv_intersects_dep(self, other) if other.is_a? Dep

        raise TypeError.new("invalid type: #{other.class}")
      end

      def to_s
        s, ptr = C.pkgcraft_cpv_str(self)
        C.pkgcraft_str_free(ptr)
        s
      end

      def <=>(other)
        C.pkgcraft_cpv_cmp(self, other)
      end

      alias eql? ==

      def hash
        @hash = C.pkgcraft_cpv_hash(self) if @hash.nil?
        @hash
      end
    end
  end
end
