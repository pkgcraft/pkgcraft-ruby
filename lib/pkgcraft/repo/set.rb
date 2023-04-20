# frozen_string_literal: true

require "set"

module Pkgcraft
  # FFI bindings for RepoSet related functionality
  module C
    # Wrapper for RepoSet pointers
    class RepoSet < AutoPointer
      def self.release(ptr)
        C.pkgcraft_repo_set_free(ptr)
      end
    end

    # repo set support
    attach_function :pkgcraft_repo_set_repos, [RepoSet, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_repo_set_cmp, [RepoSet, RepoSet], :int
    attach_function :pkgcraft_repo_set_hash, [RepoSet], :uint64
    attach_function :pkgcraft_repo_set_iter, [RepoSet, Restrict], :pointer
    attach_function :pkgcraft_repo_set_iter_free, [:pointer], :void
    attach_function :pkgcraft_repo_set_iter_next, [:pointer], Pkgcraft::Pkgs::Pkg
    attach_function :pkgcraft_repo_set_len, [RepoSet], :uint64
    attach_function :pkgcraft_repo_set_is_empty, [RepoSet], :bool
    attach_function :pkgcraft_repo_set_new, [:pointer, :uint64], RepoSet
    attach_function :pkgcraft_repo_set_free, [:pointer], :void
  end

  module Repos
    # Ordered repository set.
    class RepoSet < C::RepoSet
      include Comparable
      include Enumerable

      def initialize(*repos)
        c_repos = FFI::MemoryPointer.new(:pointer, repos.length)
        c_repos.write_array_of_pointer(repos.map { |r| r.instance_variable_get(:@ptr) })
        @ptr = C.pkgcraft_repo_set_new(c_repos, repos.length)
      end

      # Iterator over a RepoSet.
      class Iter
        include Enumerable
        include Pkgcraft::Restricts

        def initialize(repo_set, restrict = nil)
          restrict =
            if restrict.nil?
              Restrict.from_native(nil)
            elsif restrict.is_a? Restrict
              restrict
            else
              Restrict.new(restrict)
            end
          ptr = C.pkgcraft_repo_set_iter(repo_set, restrict)
          @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_set_iter_free))
        end

        def each
          loop do
            pkg = C.pkgcraft_repo_set_iter_next(@ptr)
            break if pkg.nil?

            yield pkg
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
        if @repos.nil?
          c_repos = C.pkgcraft_repo_set_repos(self, length)
          repos = Configs.send(:repos_to_dict, c_repos, length[:value], true)
          @repos = Set.new(repos.values)
          C.pkgcraft_repos_free(c_repos, length[:value])
        end
        @repos
      end

      def contains?(obj)
        return repos.include?(obj) if obj.is_a? Repo

        repos.any? { |r| r.contains?(obj) }
      end

      def <=>(other)
        C.pkgcraft_repo_set_cmp(self, other)
      end

      alias eql? ==

      def hash
        @hash = C.pkgcraft_repo_set_hash(self) if @hash.nil?
        @hash
      end

      def length
        C.pkgcraft_repo_set_len(self)
      end

      def empty?
        C.pkgcraft_repo_set_is_empty(self)
      end
    end
  end
end
