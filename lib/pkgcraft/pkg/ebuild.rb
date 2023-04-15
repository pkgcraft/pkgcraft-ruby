# frozen_string_literal: true

module Pkgcraft
  module Pkg
    # Ebuild package.
    class Ebuild < Pkg
      def path
        s, c_str = C.pkgcraft_pkg_ebuild_path(@ptr)
        C.pkgcraft_str_free(c_str)
        Pathname.new(s)
      end

      def ebuild
        s, c_str = C.pkgcraft_pkg_ebuild_ebuild(@ptr)
        raise Error::PkgcraftError if c_str.null?

        C.pkgcraft_str_free(c_str)
        s
      end

      def description
        s, c_str = C.pkgcraft_pkg_ebuild_description(@ptr)
        C.pkgcraft_str_free(c_str)
        s
      end

      def slot
        s, c_str = C.pkgcraft_pkg_ebuild_slot(@ptr)
        C.pkgcraft_str_free(c_str)
        s
      end

      def subslot
        s, c_str = C.pkgcraft_pkg_ebuild_subslot(@ptr)
        C.pkgcraft_str_free(c_str)
        s
      end

      def long_description
        s, c_str = C.pkgcraft_pkg_ebuild_long_description(@ptr)
        return if c_str.null?

        C.pkgcraft_str_free(c_str)
        s
      end
    end
  end
end
