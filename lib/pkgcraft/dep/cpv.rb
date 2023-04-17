# frozen_string_literal: true

module Pkgcraft
  module Dep
    # CPV object support (category/package-version)
    class Cpv
      include Comparable
      attr_reader :ptr

      def initialize(str)
        @ptr = C.pkgcraft_cpv_new(str.to_s)
        raise Error::InvalidCpv if ptr.null?
      end

      # Create a Cpv from a pointer.
      def self.from_ptr(ptr)
        obj = allocate
        obj.instance_variable_set(:@ptr, ptr)
        obj
      end

      private_class_method :from_ptr

      def category
        @_category, ptr = C.pkgcraft_cpv_category(@ptr) if @_category.nil?
        C.pkgcraft_str_free(ptr)
        @_category
      end

      def package
        @_package, ptr = C.pkgcraft_cpv_package(@ptr) if @_package.nil?
        C.pkgcraft_str_free(ptr)
        @_package
      end

      def version
        @_version = Version.send(:from_ptr, C.pkgcraft_cpv_version(@ptr)) if @_version.nil?
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

      def inspect
        "#<#{self.class} '#{self}'>"
      end

      def <=>(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? Cpv

        C.pkgcraft_cpv_cmp(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        @_hash = C.pkgcraft_cpv_hash(@ptr) if @_hash.nil?
        @_hash
      end
    end
  end
end
