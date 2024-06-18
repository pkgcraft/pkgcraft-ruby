# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for ebuild package related functionality
  module C
    # ebuild pkg support
    attach_function :pkgcraft_pkg_ebuild_bdepend, [Pkg], :DependencySet
    attach_function :pkgcraft_pkg_ebuild_defined_phases, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_depend, [Pkg], :DependencySet
    attach_function :pkgcraft_pkg_ebuild_dependencies, [Pkg, :pointer, :size_t], :DependencySet
    attach_function :pkgcraft_pkg_ebuild_description, [Pkg], String
    attach_function :pkgcraft_pkg_ebuild_deprecated, [Pkg], :bool
    attach_function :pkgcraft_pkg_ebuild_ebuild, [Pkg], String
    attach_function :pkgcraft_pkg_ebuild_homepage, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_idepend, [Pkg], :DependencySet
    attach_function :pkgcraft_pkg_ebuild_inherit, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_inherited, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_iuse, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_keywords_str, [Pkg, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_pkg_ebuild_license, [Pkg], :DependencySet
    attach_function :pkgcraft_pkg_ebuild_long_description, [Pkg], String
    attach_function :pkgcraft_pkg_ebuild_masked, [Pkg], :bool
    attach_function :pkgcraft_pkg_ebuild_path, [Pkg], String
    attach_function :pkgcraft_pkg_ebuild_pdepend, [Pkg], :DependencySet
    attach_function :pkgcraft_pkg_ebuild_properties, [Pkg], :DependencySet
    attach_function :pkgcraft_pkg_ebuild_rdepend, [Pkg], :DependencySet
    attach_function :pkgcraft_pkg_ebuild_required_use, [Pkg], :DependencySet
    attach_function :pkgcraft_pkg_ebuild_restrict, [Pkg], :DependencySet
    attach_function :pkgcraft_pkg_ebuild_slot, [Pkg], String
    attach_function :pkgcraft_pkg_ebuild_src_uri, [Pkg], :DependencySet
    attach_function :pkgcraft_pkg_ebuild_subslot, [Pkg], String
  end

  module Pkgs
    # Ebuild package.
    class Ebuild < Pkg
      include Pkgcraft::Dep

      def path
        Pathname.new(C.pkgcraft_pkg_ebuild_path(self))
      end

      def ebuild
        s = C.pkgcraft_pkg_ebuild_ebuild(self)
        raise Error::PkgcraftError if s.nil?

        s
      end

      def deprecated
        C.pkgcraft_pkg_ebuild_deprecated(self)
      end

      def masked
        C.pkgcraft_pkg_ebuild_masked(self)
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

        DependencySet.send(:from_ptr, ptr)
      end

      def depend
        if @depend.nil?
          ptr = C.pkgcraft_pkg_ebuild_depend(self)
          @depend = DependencySet.send(:from_ptr, ptr)
        end
        @depend
      end

      def bdepend
        if @bdepend.nil?
          ptr = C.pkgcraft_pkg_ebuild_bdepend(self)
          @bdepend = DependencySet.send(:from_ptr, ptr)
        end
        @bdepend
      end

      def idepend
        if @idepend.nil?
          ptr = C.pkgcraft_pkg_ebuild_idepend(self)
          @idepend = DependencySet.send(:from_ptr, ptr)
        end
        @idepend
      end

      def pdepend
        if @pdepend.nil?
          ptr = C.pkgcraft_pkg_ebuild_pdepend(self)
          @pdepend = DependencySet.send(:from_ptr, ptr)
        end
        @pdepend
      end

      def rdepend
        if @rdepend.nil?
          ptr = C.pkgcraft_pkg_ebuild_rdepend(self)
          @rdepend = DependencySet.send(:from_ptr, ptr)
        end
        @rdepend
      end

      def license
        if @license.nil?
          ptr = C.pkgcraft_pkg_ebuild_license(self)
          @license = DependencySet.send(:from_ptr, ptr)
        end
        @license
      end

      def properties
        if @properties.nil?
          ptr = C.pkgcraft_pkg_ebuild_properties(self)
          @properties = DependencySet.send(:from_ptr, ptr)
        end
        @properties
      end

      def required_use
        if @required_use.nil?
          ptr = C.pkgcraft_pkg_ebuild_required_use(self)
          @required_use = DependencySet.send(:from_ptr, ptr)
        end
        @required_use
      end

      def restrict
        if @restrict.nil?
          ptr = C.pkgcraft_pkg_ebuild_restrict(self)
          @restrict = DependencySet.send(:from_ptr, ptr)
        end
        @restrict
      end

      def src_uri
        if @src_uri.nil?
          ptr = C.pkgcraft_pkg_ebuild_src_uri(self)
          @src_uri = DependencySet.send(:from_ptr, ptr)
        end
        @src_uri
      end

      def defined_phases
        if @defined_phases.nil?
          values = C.ptr_to_string_array(C.method(:pkgcraft_pkg_ebuild_defined_phases), self)
          @defined_phases = Set.new(values).freeze
        end
        @defined_phases
      end

      def homepage
        if @homepage.nil?
          values = C.ptr_to_string_array(C.method(:pkgcraft_pkg_ebuild_homepage), self)
          @homepage = Set.new(values).freeze
        end
        @homepage
      end

      def keywords
        if @keywords.nil?
          values = C.ptr_to_string_array(C.method(:pkgcraft_pkg_ebuild_keywords_str), self)
          @keywords = Set.new(values).freeze
        end
        @keywords
      end

      def iuse
        if @iuse.nil?
          values = C.ptr_to_string_array(C.method(:pkgcraft_pkg_ebuild_iuse), self)
          @iuse = Set.new(values).freeze
        end
        @iuse
      end

      def inherit
        if @inherit.nil?
          values = C.ptr_to_string_array(C.method(:pkgcraft_pkg_ebuild_inherit), self)
          @inherit = Set.new(values).freeze
        end
        @inherit
      end

      def inherited
        if @inherited.nil?
          values = C.ptr_to_string_array(C.method(:pkgcraft_pkg_ebuild_inherited), self)
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
