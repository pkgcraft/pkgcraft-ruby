# frozen_string_literal: true

module Pkgcraft
  module Repo
    # Ebuild package repo.
    class Ebuild < Repo
      include Eapis

      def eapi
        @_eapi = Eapi.send(:from_ptr, C.pkgcraft_repo_ebuild_eapi(@ptr)) if @_eapi.nil?
        @_eapi
      end

      def masters
        if @_masters.nil?
          length = C::LenPtr.new
          c_repos = C.pkgcraft_repo_ebuild_masters(@ptr, length)
          repos = Config.send(:repos_to_dict, c_repos, length[:value], false)
          @_masters = repos.values
        end
        @_masters
      end
    end
  end
end
