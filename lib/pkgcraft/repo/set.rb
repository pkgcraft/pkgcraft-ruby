# frozen_string_literal: true

require "set"

module Pkgcraft
  module Repos
    # Ordered repository set.
    class RepoSet < C::RepoSet
      include Comparable
      include Enumerable

      def initialize(*repos)
        c_repos = FFI::MemoryPointer.new(:pointer, repos.length)
        c_repos.write_array_of_pointer(repos.map(&:ptr))
        obj = C.pkgcraft_repo_set_new(c_repos, repos.length)
        @ptr = obj.instance_variable_get(:@ptr)
      end

      # Create a RepoSet from a pointer.
      def self.from_ptr(ptr)
        obj = allocate
        obj.instance_variable_set(:@ptr, ptr)
        obj
      end

      private_class_method :from_ptr

      # Iterator over a RepoSet.
      class Iter
        include Enumerable
        include Pkgcraft::Restricts

        def initialize(repo_set, restrict = nil)
          restrict_ptr =
            if restrict.nil?
              nil
            elsif restrict.is_a? Restrict
              restrict.ptr
            else
              Restrict.new(restrict).ptr
            end
          ptr = C.pkgcraft_repo_set_iter(repo_set, restrict_ptr)
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
