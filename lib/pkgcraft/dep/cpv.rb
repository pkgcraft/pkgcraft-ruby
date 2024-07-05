# frozen_string_literal: true

module Pkgcraft
  module Dep
    # CPV object support (category/package-version)
    class Cpv < C::Cpv
      include InspectPointerRender
      include Comparable

      # Create a Cpv from a pointer.
      def self.from_ptr(ptr)
        obj = allocate
        obj.instance_variable_set(:@ptr, ptr)
        obj
      end

      private_class_method :from_ptr

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
        if @version.nil?
          ptr = C.pkgcraft_cpv_version(self)
          @version = Version.send(:from_ptr, ptr)
        end
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
        ptr = C.pkgcraft_cpv_cpn(self)
        Cpn.send(:from_ptr, ptr)
      end

      def intersects(other)
        return C.pkgcraft_cpv_intersects(self, other) if other.is_a? Cpv
        return C.pkgcraft_cpv_intersects_dep(self, other) if other.is_a? Dep
        return C.pkgcraft_pkg_intersects_cpv(other, self) if other.is_a? Pkgcraft::Pkgs::Pkg

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

  # FFI bindings for Cpv related functionality
  module C
    attach_function :pkgcraft_cpv_category, [Cpv], String
    attach_function :pkgcraft_cpv_cmp, [Cpv, Cpv], :int
    attach_function :pkgcraft_cpv_cpn, [Cpv], Cpn
    attach_function :pkgcraft_cpv_free, [:pointer], :void
    attach_function :pkgcraft_cpv_hash, [Cpv], :uint64
    attach_function :pkgcraft_cpv_intersects, [Cpv, Cpv], :bool
    attach_function :pkgcraft_cpv_intersects_dep, [Cpv, Dep], :bool
    attach_function :pkgcraft_cpv_new, [:string], Cpv
    attach_function :pkgcraft_cpv_p, [Cpv], String
    attach_function :pkgcraft_cpv_package, [Cpv], String
    attach_function :pkgcraft_cpv_pf, [Cpv], String
    attach_function :pkgcraft_cpv_pr, [Cpv], String
    attach_function :pkgcraft_cpv_pv, [Cpv], String
    attach_function :pkgcraft_cpv_pvr, [Cpv], String
    attach_function :pkgcraft_cpv_restrict, [Cpv], Restrict
    attach_function :pkgcraft_cpv_str, [Cpv], String
    attach_function :pkgcraft_cpv_version, [Cpv], Version
  end
end
