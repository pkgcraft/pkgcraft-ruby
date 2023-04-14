# frozen_string_literal: true

module Pkgcraft
  module Repos
    # Temporary ebuild package repo.
    class EbuildTemp < Ebuild
      def initialize(id: "test", eapi: EAPI_LATEST_OFFICIAL, priority: 0)
        eapi = Eapi.from_obj(eapi)
        ptr = C.pkgcraft_repo_ebuild_temp_new(id, eapi.ptr)
        raise Error::PkgcraftError if ptr.null?

        @ptr_temp = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_ebuild_temp_free))
        path = C.pkgcraft_repo_ebuild_temp_path(@ptr_temp)
        super(path, id, priority)
      end

      def create_ebuild(cpv, *keys)
        ptr = FFI::MemoryPointer.new(:pointer, keys.length)
        ptr.write_array_of_pointer(keys.map { |s| FFI::MemoryPointer.from_string(s) })
        path, c_str = C.pkgcraft_repo_ebuild_temp_create_ebuild(@ptr_temp, cpv, ptr, keys.length)
        raise Error::PkgcraftError if c_str.null?

        C.pkgcraft_str_free(c_str)
        Pathname.new(path)
      end

      def create_pkg(cpv, *keys)
        create_ebuild(cpv, *keys)
        iter(cpv).first
      end
    end
  end
end