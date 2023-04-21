# frozen_string_literal: true

module Pkgcraft
  module Repos
    # Ebuild package repo.
    class Ebuild < Repo
      include Eapis

      def eapi
        @eapi = Eapi.send(:from_ptr, C.pkgcraft_repo_ebuild_eapi(@ptr)) if @eapi.nil?
        @eapi
      end

      def masters
        if @masters.nil?
          length = C::LenPtr.new
          c_repos = C.pkgcraft_repo_ebuild_masters(@ptr, length)
          repos = Configs.send(:repos_to_dict, c_repos, length[:value], false)
          @masters = repos.values
        end
        @masters
      end

      def metadata
        @metadata = Metadata.new(@ptr) if @metadata.nil?
        @metadata
      end
    end

    # Ebuild repo metadata.
    class Metadata
      def initialize(ptr)
        @ptr = ptr
      end

      def arches
        if @arches.nil?
          @arches = C.ptr_to_array(@ptr, C.method(:pkgcraft_repo_ebuild_metadata_arches))
        end
        @arches
      end

      def categories
        if @categories.nil?
          @categories = C.ptr_to_array(@ptr, C.method(:pkgcraft_repo_ebuild_metadata_categories))
        end
        @categories
      end
    end
  end
end
