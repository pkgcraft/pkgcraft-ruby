# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for Pkg related functionality
  module C
    # Wrapper for Pkg objects
    class Pkg < AutoPointer
      def self.from_native(value, _context)
        return if value.null?

        format = C.pkgcraft_pkg_format(value)
        case format
        when 0
          obj = Pkgs::Ebuild.allocate
          obj.class.instance_method(:initialize).bind(obj).call
        when 1
          obj = Pkgs::Fake.allocate
        else
          "unsupported pkg format: #{format}"
        end

        FFI::AutoPointer.instance_method(:initialize).bind(obj).call(value)
        obj.instance_variable_set(:@ptr, value)
        obj
      end

      def self.release(ptr)
        C.pkgcraft_pkg_free(ptr)
      end
    end

    # pkg support
    attach_function :pkgcraft_pkg_format, [:pointer], :int
    attach_function :pkgcraft_pkg_free, [:pointer], :void
    attach_function :pkgcraft_pkg_cpv, [Pkg], Pkgcraft::Dep::Cpv
    attach_function :pkgcraft_pkg_eapi, [Pkg], :eapi
    attach_function :pkgcraft_pkg_repo, [Pkg], :pointer
    attach_function :pkgcraft_pkg_version, [Pkg], Pkgcraft::Dep::Version
    attach_function :pkgcraft_pkg_cmp, [Pkg, Pkg], :int
    attach_function :pkgcraft_pkg_hash, [Pkg], :uint64
    attach_function :pkgcraft_pkg_str, [Pkg], :strptr
    attach_function :pkgcraft_pkg_restrict, [Pkg], Restrict
  end

  # Package support
  module Pkgs
    # Generic package.
    class Pkg < C::Pkg
      include InspectPointerRender
      include Comparable

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
        @cpv = C.pkgcraft_pkg_cpv(self) if @cpv.nil?
        @cpv
      end

      def eapi
        @eapi = Eapis::Eapi.send(:from_ptr, C.pkgcraft_pkg_eapi(self)) if @eapi.nil?
        @eapi
      end

      def repo
        @repo = Repos::Repo.send(:from_ptr, C.pkgcraft_pkg_repo(self), true) if @repo.nil?
        @repo
      end

      def version
        @version = C.pkgcraft_pkg_version(self) if @version.nil?
        @version
      end

      def <=>(other)
        C.pkgcraft_pkg_cmp(self, other)
      end

      alias eql? ==

      def hash
        @hash = C.pkgcraft_pkg_hash(self) if @hash.nil?
        @hash
      end

      def to_s
        s, c_str = C.pkgcraft_pkg_str(self)
        C.pkgcraft_str_free(c_str)
        s
      end
    end
  end
end
