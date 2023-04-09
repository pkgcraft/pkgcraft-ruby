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
    end
  end
end
