# frozen_string_literal: true

module Pkgcraft
  module Repos
    # Ordered repository set.
    class RepoSet
      include Comparable
      include Enumerable
      attr_reader :ptr

      # Iterator over a RepoSet.
      class Iter
        def initialize(repo_set)
          ptr = C.pkgcraft_repo_set_iter(repo_set.ptr, nil)
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

      # Create a RepoSet from a pointer.
      def self.from_ptr(ptr)
        ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_set_free))
        obj = allocate
        obj.instance_variable_set(:@ptr, ptr)
        obj
      end

      private_class_method :from_ptr

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

      def each(&block)
        Iter.new(self).each(&block)
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
        repos.length
      end
    end
  end
end
