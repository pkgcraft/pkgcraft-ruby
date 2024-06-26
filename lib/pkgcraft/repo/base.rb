# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for generic repo related functionality
  module C
    typedef :pointer, :repo
    attach_function :pkgcraft_repo_categories, [:repo, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_repo_cmp, [:repo, :repo], :int
    attach_function :pkgcraft_repo_contains_path, [:repo, :string], :bool
    attach_function :pkgcraft_repo_format, [:repo], :int
    attach_function :pkgcraft_repo_free, [:repo], :void
    attach_function :pkgcraft_repo_from_path, [:string, :int, :string, :bool], :repo
    attach_function :pkgcraft_repo_hash, [:repo], :uint64
    attach_function :pkgcraft_repo_id, [:repo], String
    attach_function :pkgcraft_repo_is_empty, [:repo], :bool
    attach_function :pkgcraft_repo_iter, [:repo], :pointer
    attach_function :pkgcraft_repo_iter_cpv, [:repo], :pointer
    attach_function :pkgcraft_repo_iter_cpv_free, [:pointer], :void
    attach_function :pkgcraft_repo_iter_cpv_next, [:pointer], Pkgcraft::Dep::Cpv
    attach_function :pkgcraft_repo_iter_free, [:pointer], :void
    attach_function :pkgcraft_repo_iter_next, [:pointer], Pkgcraft::Pkgs::Pkg
    attach_function :pkgcraft_repo_iter_restrict, [:repo, Restrict], :pointer
    attach_function :pkgcraft_repo_iter_restrict_free, [:repo], :void
    attach_function :pkgcraft_repo_iter_restrict_next, [:pointer], Pkgcraft::Pkgs::Pkg
    attach_function :pkgcraft_repo_len, [:repo], :uint64
    attach_function :pkgcraft_repo_packages, [:repo, :string, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_repo_path, [:repo], String
    attach_function :pkgcraft_repo_versions, [:repo, :string, :string, LenPtr.by_ref], :pointer
  end

  # Repo support
  module Repos
    # Package repo.
    class Repo
      include InspectPointerRender
      include Comparable
      include Enumerable
      attr_reader :id
      attr_reader :ptr

      def initialize(path, id = nil, priority = 0)
        id = path if id.nil?
        ptr = C.pkgcraft_repo_from_path(id, priority, path, true)
        raise Error::InvalidRepo if ptr.null?

        Repo.send(:from_ptr, ptr, false, self)
      end

      # Create a Repo from a pointer.
      def self.from_ptr(ptr, ref, obj = nil)
        if obj.nil?
          format = C.pkgcraft_repo_format(ptr)
          case format
          when 0
            obj = Ebuild.allocate
          when 1
            obj = Fake.allocate
          else
            "unsupported repo format: #{format}"
          end
        end

        ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_free)) unless ref
        obj.instance_variable_set(:@ptr, ptr)
        id = C.pkgcraft_repo_id(ptr)
        obj.instance_variable_set(:@id, id)
        obj
      end

      private_class_method :from_ptr

      # Iterator of Cpvs over a repo.
      class IterCpv
        include Enumerable

        def initialize(repo_ptr)
          ptr = C.pkgcraft_repo_iter_cpv(repo_ptr)
          @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_iter_cpv_free))
        end

        def each
          loop do
            cpv = C.pkgcraft_repo_iter_cpv_next(@ptr)
            break if cpv.null?

            yield cpv
          end
        end
      end

      private_constant :IterCpv

      # Iterator of packages over a repo.
      class Iter
        include Enumerable

        def initialize(repo_ptr)
          ptr = C.pkgcraft_repo_iter(repo_ptr)
          @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_iter_free))
        end

        def each
          loop do
            pkg = C.pkgcraft_repo_iter_next(@ptr)
            break if pkg.nil?

            yield pkg
          end
        end
      end

      private_constant :Iter

      # Iterator of packages that applies a restriction over a repo.
      class IterRestrict
        include Enumerable
        include Pkgcraft::Restricts

        def initialize(repo_ptr, obj)
          restrict =
            if obj.is_a? Restrict
              obj
            else
              Restrict.new(obj)
            end
          ptr = C.pkgcraft_repo_iter_restrict(repo_ptr, restrict)
          @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_iter_restrict_free))
        end

        def each
          loop do
            pkg = C.pkgcraft_repo_iter_restrict_next(@ptr)
            break if pkg.nil?

            yield pkg
          end
        end
      end

      private_constant :IterRestrict

      def iter_cpv
        IterCpv.new(@ptr)
      end

      def iter(restrict = nil)
        return Iter.new(@ptr) if restrict.nil?

        IterRestrict.new(@ptr, restrict)
      end

      def each(restrict = nil, &)
        iter(restrict).each(&)
      end

      def [](cpv)
        iter(cpv).first
      end

      def path
        @path = Pathname.new(C.pkgcraft_repo_path(@ptr)) if @path.nil?
        @path
      end

      def categories
        C.ptr_to_string_array(C.method(:pkgcraft_repo_categories), @ptr).freeze
      end

      def packages(cat)
        C.ptr_to_string_array(C.method(:pkgcraft_repo_packages), @ptr, cat).freeze
      end

      def versions(cat, pkg)
        C.ptr_to_obj_array(
          Pkgcraft::Dep::Version,
          C.method(:pkgcraft_repo_versions), @ptr, cat, pkg
        ).freeze
      end

      def length
        C.pkgcraft_repo_len(@ptr)
      end

      def empty?
        C.pkgcraft_repo_is_empty(@ptr)
      end

      def contains?(obj)
        if [String, Pathname].any? { |c| obj.is_a? c }
          C.pkgcraft_repo_contains_path(@ptr, obj.to_s)
        else
          !iter(obj).first.nil?
        end
      end

      def <=>(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? Repo

        C.pkgcraft_repo_cmp(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        @hash = C.pkgcraft_repo_hash(@ptr) if @hash.nil?
        @hash
      end

      def to_s
        @id
      end
    end
  end
end
