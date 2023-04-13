# frozen_string_literal: true

require "set"

module Pkgcraft
  module Repos
    # Ordered repository set.
    class RepoSet
      include Comparable
      include Enumerable
      attr_reader :ptr

      def initialize(*repos)
        ptr = FFI::MemoryPointer.new(:pointer, repos.length)
        ptr.write_array_of_pointer(repos.map(&:ptr))
        self.ptr = C.pkgcraft_repo_set_new(ptr, repos.length)
      end

      # Create a RepoSet from a pointer.
      def self.from_ptr(ptr)
        obj = allocate
        obj.send(:ptr=, ptr)
        obj
      end

      private_class_method :from_ptr

      # Iterator over a RepoSet.
      class Iter
        include Enumerable

        def initialize(repo, restrict = nil)
          restrict_ptr =
            if restrict.nil?
              nil
            elsif restrict.is_a? Pkgcraft::Restrict::Restrict
              restrict.ptr
            else
              Pkgcraft::Restrict::Restrict.new(restrict).ptr
            end
          ptr = C.pkgcraft_repo_set_iter(repo.ptr, restrict_ptr)
          @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_set_iter_free))
        end

        def each
          loop do
            ptr = C.pkgcraft_repo_set_iter_next(@ptr)
            break if ptr.null?

            yield Pkg.send(:from_ptr, ptr)
          end
        end
      end

      private_constant :Iter

      def iter(restrict = nil)
        Iter.new(self, restrict)
      end

      def each(restrict = nil, &block)
        iter(restrict).each(&block)
      end

      def repos
        length = C::LenPtr.new
        if @_repos.nil?
          c_repos = C.pkgcraft_repo_set_repos(@ptr, length)
          repos = Config.send(:repos_to_dict, c_repos, length[:value], true)
          @_repos = Set.new(repos.values)
          C.pkgcraft_repos_free(c_repos, length[:value])
        end
        @_repos
      end

      def <=>(other)
        return C.pkgcraft_repo_set_cmp(@ptr, other.ptr) if other.is_a? RepoSet

        raise TypeError.new("invalid type: #{other.class}")
      end

      def hash
        @_hash = C.pkgcraft_repo_set_hash(@ptr) if @_hash.nil?
        @_hash
      end

      def length
        C.pkgcraft_repo_set_len(@ptr)
      end

      def empty?
        C.pkgcraft_repo_set_is_empty(@ptr)
      end

      def ptr=(ptr)
        @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_set_free))
      end
    end
  end
end
