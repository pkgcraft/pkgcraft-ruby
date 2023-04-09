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

      ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_pkg_free))
      obj.instance_variable_set(:@ptr, ptr)
      obj
    end

    private_class_method :from_ptr

    # Generic package.
    class Pkg
      include Comparable

      include Dep
      include Eapis

      attr_reader :ptr

      def cpv
        @_cpv = Cpv.send(:from_ptr, C.pkgcraft_pkg_cpv(@ptr)) if @_cpv.nil?
        @_cpv
      end

      def eapi
        @_eapi = Eapi.send(:from_ptr, C.pkgcraft_pkg_eapi(@ptr)) if @_eapi.nil?
        @_eapi
      end

      def repo
        @_repo = Repo.send(:from_ptr, C.pkgcraft_pkg_repo(@ptr), true) if @_repo.nil?
        @_repo
      end

      def version
        @_version = Version.send(:from_ptr, C.pkgcraft_pkg_version(@ptr)) if @_version.nil?
        @_version
      end

      def <=>(other)
        return C.pkgcraft_pkg_cmp(@ptr, other.ptr) if other.is_a? Pkg

        raise TypeError.new("invalid type: #{other.class}")
      end

      def hash
        @_hash = C.pkgcraft_pkg_hash(@ptr) if @_hash.nil?
        @_hash
      end

      def to_s
        s, c_str = C.pkgcraft_pkg_str(@ptr)
        C.pkgcraft_str_free(c_str)
        s
      end
    end
  end
end
