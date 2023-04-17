# frozen_string_literal: true

module Pkgcraft
  # Package support
  module Pkg
    # Create a Pkg from a pointer.
    def self.from_ptr(ptr)
      format = C.pkgcraft_pkg_format(ptr)
      case format
      when 0
        obj = Ebuild.allocate
      when 1
        obj = Fake.allocate
      else
        "unsupported pkg format: #{format}"
      end

      obj.instance_variable_set(:@ptr, ptr)
      obj.send(:initialize)
      obj
    end

    private_class_method :from_ptr

    # Generic package.
    class Pkg
      include Comparable

      attr_reader :ptr

      def p
        cpv.p
      end

      def pf
        cpv.pf
      end

      def pr
        cpv.pr
      end

      def pv
        cpv.pv
      end

      def pvr
        cpv.pvr
      end

      def cpn
        cpv.cpn
      end

      def cpv
        @_cpv = Dep::Cpv.send(:from_ptr, C.pkgcraft_pkg_cpv(@ptr)) if @_cpv.nil?
        @_cpv
      end

      def eapi
        @_eapi = Eapis::Eapi.send(:from_ptr, C.pkgcraft_pkg_eapi(@ptr)) if @_eapi.nil?
        @_eapi
      end

      def repo
        @_repo = Repos::Repo.send(:from_ptr, C.pkgcraft_pkg_repo(@ptr), true) if @_repo.nil?
        @_repo
      end

      def version
        @_version = Dep::Version.send(:from_ptr, C.pkgcraft_pkg_version(@ptr)) if @_version.nil?
        @_version
      end

      def <=>(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? Pkg

        C.pkgcraft_pkg_cmp(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        @_hash = C.pkgcraft_pkg_hash(@ptr) if @_hash.nil?
        @_hash
      end

      def to_s
        s, c_str = C.pkgcraft_pkg_str(@ptr)
        C.pkgcraft_str_free(c_str)
        s
      end

      def inspect
        "#<#{self.class} '#{self}' at #{@ptr.address}>"
      end
    end
  end
end
