# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for ebuild package related functionality
  module C
    # ebuild pkg support
    attach_function :pkgcraft_pkg_ebuild_path, [Pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_ebuild, [Pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_description, [Pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_slot, [Pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_subslot, [Pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_long_description, [Pkg], :strptr
    attach_function :pkgcraft_pkg_ebuild_dependencies, [Pkg, :pointer, :size_t], :DepSet
    attach_function :pkgcraft_pkg_ebuild_depend, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_bdepend, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_idepend, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_pdepend, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_rdepend, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_license, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_properties, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_required_use, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_restrict, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_src_uri, [Pkg], :DepSet
    attach_function :pkgcraft_pkg_ebuild_defined_phases, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_homepage, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_keywords, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_iuse, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_inherit, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_inherited, [Pkg, LenPtr.by_ref], :pointer
  end

  module Pkgs
    # Ebuild package.
    class Ebuild < Pkg
      include Pkgcraft::Dep

      def initialize
        @depend = SENTINEL
        @bdepend = SENTINEL
        @idepend = SENTINEL
        @pdepend = SENTINEL
        @rdepend = SENTINEL
        @license = SENTINEL
        @properties = SENTINEL
        @required_use = SENTINEL
        @restrict = SENTINEL
        @src_uri = SENTINEL
      end

      def path
        s, c_str = C.pkgcraft_pkg_ebuild_path(self)
        C.pkgcraft_str_free(c_str)
        Pathname.new(s)
      end

      def ebuild
        s, c_str = C.pkgcraft_pkg_ebuild_ebuild(self)
        raise Error::PkgcraftError if c_str.null?

        C.pkgcraft_str_free(c_str)
        s
      end

      def description
        s, c_str = C.pkgcraft_pkg_ebuild_description(self)
        C.pkgcraft_str_free(c_str)
        s
      end

      def slot
        s, c_str = C.pkgcraft_pkg_ebuild_slot(self)
        C.pkgcraft_str_free(c_str)
        s
      end

      def subslot
        s, c_str = C.pkgcraft_pkg_ebuild_subslot(self)
        C.pkgcraft_str_free(c_str)
        s
      end

      def dependencies(*keys)
        c_keys = FFI::MemoryPointer.new(:pointer, keys.length)
        c_keys.write_array_of_pointer(keys.map { |s| FFI::MemoryPointer.from_string(s) })
        ptr = C.pkgcraft_pkg_ebuild_dependencies(self, c_keys, keys.length)
        raise Error::PkgcraftError if ptr.null?

        DepSet.send(:from_ptr, ptr)
      end

      def depend
        if @depend.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_depend(self)
          @depend = Dependencies.send(:from_ptr, ptr)
        end
        @depend
      end

      def bdepend
        if @bdepend.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_bdepend(self)
          @bdepend = Dependencies.send(:from_ptr, ptr)
        end
        @bdepend
      end

      def idepend
        if @idepend.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_idepend(self)
          @idepend = Dependencies.send(:from_ptr, ptr)
        end
        @idepend
      end

      def pdepend
        if @pdepend.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_pdepend(self)
          @pdepend = Dependencies.send(:from_ptr, ptr)
        end
        @pdepend
      end

      def rdepend
        if @rdepend.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_rdepend(self)
          @rdepend = Dependencies.send(:from_ptr, ptr)
        end
        @rdepend
      end

      def license
        if @license.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_license(self)
          @license = License.send(:from_ptr, ptr)
        end
        @license
      end

      def properties
        if @properties.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_properties(self)
          @properties = Properties.send(:from_ptr, ptr)
        end
        @properties
      end

      def required_use
        if @required_use.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_required_use(self)
          @required_use = RequiredUse.send(:from_ptr, ptr)
        end
        @required_use
      end

      def restrict
        if @restrict.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_restrict(self)
          @restrict = Restrict.send(:from_ptr, ptr)
        end
        @restrict
      end

      def src_uri
        if @src_uri.equal?(SENTINEL)
          ptr = C.pkgcraft_pkg_ebuild_src_uri(self)
          @src_uri = SrcUri.send(:from_ptr, ptr)
        end
        @src_uri
      end

      def defined_phases
        if @defined_phases.nil?
          length = C::LenPtr.new
          ptr = C.pkgcraft_pkg_ebuild_defined_phases(self, length)
          @defined_phases = Set.new(ptr.get_array_of_string(0, length[:value])).freeze
          C.pkgcraft_str_array_free(ptr, length[:value])
        end
        @defined_phases
      end

      def homepage
        if @homepage.nil?
          length = C::LenPtr.new
          ptr = C.pkgcraft_pkg_ebuild_homepage(self, length)
          @homepage = Set.new(ptr.get_array_of_string(0, length[:value])).freeze
          C.pkgcraft_str_array_free(ptr, length[:value])
        end
        @homepage
      end

      def keywords
        if @keywords.nil?
          length = C::LenPtr.new
          ptr = C.pkgcraft_pkg_ebuild_keywords(self, length)
          @keywords = Set.new(ptr.get_array_of_string(0, length[:value])).freeze
          C.pkgcraft_str_array_free(ptr, length[:value])
        end
        @keywords
      end

      def iuse
        if @iuse.nil?
          length = C::LenPtr.new
          ptr = C.pkgcraft_pkg_ebuild_iuse(self, length)
          @iuse = Set.new(ptr.get_array_of_string(0, length[:value])).freeze
          C.pkgcraft_str_array_free(ptr, length[:value])
        end
        @iuse
      end

      def inherit
        if @inherit.nil?
          length = C::LenPtr.new
          ptr = C.pkgcraft_pkg_ebuild_inherit(self, length)
          @inherit = Set.new(ptr.get_array_of_string(0, length[:value])).freeze
          C.pkgcraft_str_array_free(ptr, length[:value])
        end
        @inherit
      end

      def inherited
        if @inherited.nil?
          length = C::LenPtr.new
          ptr = C.pkgcraft_pkg_ebuild_inherited(self, length)
          @inherited = Set.new(ptr.get_array_of_string(0, length[:value])).freeze
          C.pkgcraft_str_array_free(ptr, length[:value])
        end
        @inherited
      end

      def long_description
        s, c_str = C.pkgcraft_pkg_ebuild_long_description(self)
        return if c_str.null?

        C.pkgcraft_str_free(c_str)
        s
      end
    end
  end
end
