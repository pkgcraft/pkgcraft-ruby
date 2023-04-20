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
        @category = C.pkgcraft_cpv_category(self) if @category.nil?
        @category
      end

      def package
        @package = C.pkgcraft_cpv_package(self) if @package.nil?
        @package
      end

      def version
        @version = C.pkgcraft_cpv_version(self) if @version.nil?
        @version
      end

      def revision
        version.revision
      end

      def p
        C.pkgcraft_cpv_p(self)
      end

      def pf
        C.pkgcraft_cpv_pf(self)
      end

      def pr
        C.pkgcraft_cpv_pr(self)
      end

      def pv
        C.pkgcraft_cpv_pv(self)
      end

      def pvr
        C.pkgcraft_cpv_pvr(self)
      end

      def cpn
        C.pkgcraft_cpv_cpn(self)
      end

      def intersects(other)
        return C.pkgcraft_cpv_intersects(self, other) if other.is_a? Cpv

        return C.pkgcraft_cpv_intersects_dep(self, other) if other.is_a? Dep

        raise TypeError.new("invalid type: #{other.class}")
      end

      def to_s
        C.pkgcraft_cpv_str(self)
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
