# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for ebuild package related functionality
  module C
    # ebuild pkg support
    attach_function :pkgcraft_pkg_ebuild_path, [Pkg], String
    attach_function :pkgcraft_pkg_ebuild_ebuild, [Pkg], String
    attach_function :pkgcraft_pkg_ebuild_description, [Pkg], String
    attach_function :pkgcraft_pkg_ebuild_slot, [Pkg], String
    attach_function :pkgcraft_pkg_ebuild_subslot, [Pkg], String
    attach_function :pkgcraft_pkg_ebuild_long_description, [Pkg], String
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
        Pathname.new(C.pkgcraft_pkg_ebuild_path(self))
      end

      def ebuild
        s = C.pkgcraft_pkg_ebuild_ebuild(self)
        raise Error::PkgcraftError if s.nil?

        s
      end

      def description
        C.pkgcraft_pkg_ebuild_description(self)
      end

      def slot
        C.pkgcraft_pkg_ebuild_slot(self)
      end

      def subslot
        C.pkgcraft_pkg_ebuild_subslot(self)
      end

      def dependencies(*keys)
        c_keys, length = C.string_iter_to_ptr(keys)
        ptr = C.pkgcraft_pkg_ebuild_dependencies(self, c_keys, length)
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
          values = C.ptr_to_string_array(self, C.method(:pkgcraft_pkg_ebuild_defined_phases))
          @defined_phases = Set.new(values).freeze
        end
        @defined_phases
      end

      def homepage
        if @homepage.nil?
          values = C.ptr_to_string_array(self, C.method(:pkgcraft_pkg_ebuild_homepage))
          @homepage = Set.new(values).freeze
        end
        @homepage
      end

      def keywords
        if @keywords.nil?
          values = C.ptr_to_string_array(self, C.method(:pkgcraft_pkg_ebuild_keywords))
          @keywords = Set.new(values).freeze
        end
        @keywords
      end

      def iuse
        if @iuse.nil?
          values = C.ptr_to_string_array(self, C.method(:pkgcraft_pkg_ebuild_iuse))
          @iuse = Set.new(values).freeze
        end
        @iuse
      end

      def inherit
        if @inherit.nil?
          values = C.ptr_to_string_array(self, C.method(:pkgcraft_pkg_ebuild_inherit))
          @inherit = Set.new(values).freeze
        end
        @inherit
      end

      def inherited
        if @inherited.nil?
          values = C.ptr_to_string_array(self, C.method(:pkgcraft_pkg_ebuild_inherited))
          @inherited = Set.new(values).freeze
        end
        @inherited
      end

      def long_description
        C.pkgcraft_pkg_ebuild_long_description(self)
      end
    end
  end
end
