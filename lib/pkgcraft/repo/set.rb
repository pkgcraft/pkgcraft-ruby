# frozen_string_literal: true

module Pkgcraft
  module Repo
    # Ordered repository set.
    class RepoSet
      # Create a RepoSet from a pointer.
      def self._from_ptr(ptr)
        ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_set_free))
        obj = allocate
        obj.instance_variable_set(:@ptr, ptr)
        obj
      end

      def repos
        length = C::LenPtr.new
        if @_repos.nil?
          c_repos = C.pkgcraft_repo_set_repos(@ptr, length)
          repos = Pkgcraft::Config._repos_to_dict(c_repos, length[:value], true)
          @_repos = Set.new(repos.values)
          C.pkgcraft_repos_free(c_repos, length[:value])
        end
        @_repos
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
