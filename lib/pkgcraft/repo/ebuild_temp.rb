# frozen_string_literal: true

module Pkgcraft
  module Repo
    # Temporary ebuild package repo.
    class EbuildTemp < Ebuild
      def initialize(id, eapi = EAPI_LATEST_OFFICIAL)
        eapi = Eapi.from_obj(eapi)
        ptr = C.pkgcraft_repo_ebuild_temp_new(id, eapi.ptr)
        @ptr_temp = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_ebuild_temp_free))
        path = C.pkgcraft_repo_ebuild_temp_path(@ptr_temp)
        super(path, id)
      end
    end
  end
end
