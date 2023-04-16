# frozen_string_literal: true

module Pkgcraft
  module Pkg
    # Ebuild package.
    class Ebuild < Pkg
      include Pkgcraft::Dep

      def initialize
        @_depend = SENTINEL
        @_bdepend = SENTINEL
        @_idepend = SENTINEL
        @_pdepend = SENTINEL
        @_rdepend = SENTINEL
      end

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

      def dependencies(*keys)
        c_keys = FFI::MemoryPointer.new(:pointer, keys.length)
        c_keys.write_array_of_pointer(keys.map { |s| FFI::MemoryPointer.from_string(s) })
        ptr = C.pkgcraft_pkg_ebuild_dependencies(@ptr, c_keys, keys.length)
        raise Error::PkgcraftError if ptr.null?

        DepSet.send(:from_ptr, ptr)
      end

      def depend
        if @_depend.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_depend(@ptr)
          @_depend = Dependencies.send(:from_ptr, ptr)
        end
        @_depend
      end

      def bdepend
        if @_bdepend.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_bdepend(@ptr)
          @_bdepend = Dependencies.send(:from_ptr, ptr)
        end
        @_bdepend
      end

      def idepend
        if @_idepend.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_idepend(@ptr)
          @_idepend = Dependencies.send(:from_ptr, ptr)
        end
        @_idepend
      end

      def pdepend
        if @_pdepend.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_pdepend(@ptr)
          @_pdepend = Dependencies.send(:from_ptr, ptr)
        end
        @_pdepend
      end

      def rdepend
        if @_rdepend.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_rdepend(@ptr)
          @_rdepend = Dependencies.send(:from_ptr, ptr)
        end
        @_rdepend
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
