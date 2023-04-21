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

      def create_ebuild(cpv, *keys, data: nil)
        c_keys, length = C.iter_to_ptr(keys)
        path = C.pkgcraft_repo_ebuild_temp_create_ebuild(@ptr_temp, cpv, c_keys, length)
        raise Error::PkgcraftError if path.nil?

        unless data.nil?
          File.open(path, "a") do |f|
            f.write(data)
          end
        end

        Pathname.new(path)
      end

      def create_ebuild_raw(cpv, data)
        path = C.pkgcraft_repo_ebuild_temp_create_ebuild_raw(@ptr_temp, cpv, data)
        raise Error::PkgcraftError if path.nil?

        Pathname.new(path)
      end

      def create_pkg(cpv, *keys, data: nil)
        create_ebuild(cpv, *keys, data: data)
        iter(cpv).first
      end
    end
  end
end
