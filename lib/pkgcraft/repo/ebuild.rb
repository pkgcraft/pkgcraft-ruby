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
    end
  end
end
