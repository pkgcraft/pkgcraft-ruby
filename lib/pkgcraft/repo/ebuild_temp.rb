# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for temporary ebuild repo related functionality
  # rubocop:disable Layout/LineLength
  module C
    attach_function :pkgcraft_repo_ebuild_temp_create_pkg, [:pointer, :string, :pointer, :uint64], Pkgcraft::Pkgs::Pkg
    attach_function :pkgcraft_repo_ebuild_temp_create_pkg_from_str, [:pointer, :string, :string], Pkgcraft::Pkgs::Pkg
    attach_function :pkgcraft_repo_ebuild_temp_free, [:pointer], :void
    attach_function :pkgcraft_repo_ebuild_temp_new, [:string, :pointer, :int], :pointer
    attach_function :pkgcraft_repo_ebuild_temp_path, [:pointer], :string
    attach_function :pkgcraft_repo_ebuild_temp_repo, [:pointer], :repo
  end
  # rubocop:enable Layout/LineLength

  module Repos
    # Temporary ebuild package repo.
    class EbuildTemp
      include Eapis

      def initialize(id: "test", eapi: EAPI_LATEST_OFFICIAL, priority: 0)
        eapi = Eapi.from_obj(eapi)
        ptr = C.pkgcraft_repo_ebuild_temp_new(id, eapi, priority)
        raise Error::PkgcraftError if ptr.null?

        @ptr_temp = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_ebuild_temp_free))
        @path = C.pkgcraft_repo_ebuild_temp_path(@ptr_temp)
      end

      def repo
        ptr = C.pkgcraft_repo_ebuild_temp_repo(@ptr_temp)
        Repo.send(:from_ptr, ptr, false)
      end

      def create_pkg(cpv, *keys)
        c_keys, length = C.string_iter_to_ptr(keys)
        pkg = C.pkgcraft_repo_ebuild_temp_create_pkg(@ptr_temp, cpv, c_keys, length)
        raise Error::PkgcraftError if pkg.nil?

        pkg
      end

      def create_pkg_from_str(cpv, data)
        pkg = C.pkgcraft_repo_ebuild_temp_create_pkg_from_str(@ptr_temp, cpv, data)
        raise Error::PkgcraftError if pkg.nil?

        pkg
      end
    end
  end
end
