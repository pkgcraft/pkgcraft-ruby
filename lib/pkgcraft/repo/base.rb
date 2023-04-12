# frozen_string_literal: true

module Pkgcraft
  # Repo support
  module Repos
    # Package repo.
    class Repo
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
        id, c_str = C.pkgcraft_repo_id(ptr)
        C.pkgcraft_str_free(c_str)
        obj.instance_variable_set(:@id, id)
        obj
      end

      private_class_method :from_ptr

      # Iterator over a repo.
      class Iter
        def initialize(repo)
          ptr = C.pkgcraft_repo_iter(repo.ptr)
          @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_iter_free))
        end

        def each
          loop do
            ptr = C.pkgcraft_repo_iter_next(@ptr)
            break if ptr.null?

            yield Pkg.send(:from_ptr, ptr)
          end
        end
      end

      private_constant :Iter

      # Iterator that applies a restriction over a repo iterator.
      class IterRestrict
        def initialize(repo, obj)
          restrict =
            if obj.is_a? Pkgcraft::Restrict::Restrict
              obj
            else
              Pkgcraft::Restrict::Restrict.new(obj)
            end
          ptr = C.pkgcraft_repo_iter_restrict(repo.ptr, restrict.ptr)
          @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_iter_restrict_free))
        end

        def each
          loop do
            ptr = C.pkgcraft_repo_iter_restrict_next(@ptr)
            break if ptr.null?

            pkg = Pkg.send(:from_ptr, ptr)
            return pkg unless block_given?

            yield pkg
          end
        end
      end

      private_constant :IterRestrict

      def each(restrict = nil, &block)
        return Iter.new(self).each(&block) if restrict.nil?

        IterRestrict.new(self, restrict).each(&block)
      end

      def path
        if @_path.nil?
          path, c_str = C.pkgcraft_repo_path(@ptr)
          @_path = Pathname.new(path)
          C.pkgcraft_str_free(c_str)
        end
        @_path
      end

      def categories
        length = C::LenPtr.new
        ptr = C.pkgcraft_repo_categories(@ptr, length)
        categories = ptr.get_array_of_string(0, length[:value])
        C.pkgcraft_str_array_free(ptr, length[:value])
        categories.freeze
      end

      def packages(cat)
        length = C::LenPtr.new
        ptr = C.pkgcraft_repo_packages(@ptr, cat, length)
        pkgs = ptr.get_array_of_string(0, length[:value])
        C.pkgcraft_str_array_free(ptr, length[:value])
        pkgs.freeze
      end

      def versions(cat, pkg)
        length = C::LenPtr.new
        ptr = C.pkgcraft_repo_versions(@ptr, cat, pkg, length)
        versions = ptr.get_array_of_string(0, length[:value])
        C.pkgcraft_str_array_free(ptr, length[:value])
        versions.freeze
      end

      def length
        C.pkgcraft_repo_len(@ptr)
      end

      def <=>(other)
        return C.pkgcraft_repo_cmp(@ptr, other.ptr) if other.is_a? Repo

        raise TypeError.new("invalid type: #{other.class}")
      end

      def hash
        @_hash = C.pkgcraft_repo_hash(@ptr) if @_hash.nil?
        @_hash
      end

      def to_s
        @id
      end
    end
  end
end
