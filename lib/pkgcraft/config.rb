# frozen_string_literal: true

require "pathname"

module Pkgcraft
  # Config support
  module Config
    PORTAGE_REPOS_CONF_DEFAULTS = [
      "/etc/portage/repos.conf",
      "/usr/share/portage/config.repos.conf"
    ].freeze

    # Convert an array of repo pointers to a mapping.
    def self.repos_to_dict(repos_ptr, length, ref)
      c_repos = repos_ptr.get_array_of_pointer(0, length)
      repos = {}
      (0...length).each do |i|
        ptr = c_repos[i]
        repo = Pkgcraft::Repos::Repo.send(:from_ptr, ptr, ref)
        repos[repo.id] = repo
      end
      repos
    end

    private_class_method :repos_to_dict

    # Config for the system.
    class Config
      def initialize
        ptr = C.pkgcraft_config_new
        @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_config_free))
      end

      def repos
        @_repos = Repos._from_config(@ptr) if @_repos.nil?
        @_repos
      end

      def load_repos_conf(path = nil)
        length = C::LenPtr.new
        if path.nil?
          PORTAGE_REPOS_CONF_DEFAULTS.each do |p|
            if Pathname.new(p).exist?
              path = p
              break
            end
          end
          raise "no repos.conf found on the system" if path.nil?
        end
        c_repos = C.pkgcraft_config_load_repos_conf(@ptr, path, length)
        raise Error::PkgcraftError if c_repos.null?

        # force repos attr refresh
        @_repos = nil

        repos = Pkgcraft::Config.send(:repos_to_dict, c_repos, length[:value], false)
        C.pkgcraft_repos_free(c_repos, length[:value])
        repos
      end
    end

    # System repositories.
    class Repos
      include Enumerable

      # Create a Repos object from a Config pointer.
      def self._from_config(ptr)
        length = C::LenPtr.new
        c_repos = C.pkgcraft_config_repos(ptr, length)
        repos = Pkgcraft::Config.send(:repos_to_dict, c_repos, length[:value], true)
        C.pkgcraft_repos_free(c_repos, length[:value])

        obj = allocate
        obj.instance_variable_set(:@config_ptr, ptr)
        obj.instance_variable_set(:@repos, repos)
        obj
      end

      def all
        if @_all.nil?
          ptr = C.pkgcraft_config_repos_set(@config_ptr, 0)
          @_all = Repo::RepoSet.send(:from_ptr, ptr)
        end
        @_all
      end

      def ebuild
        if @_ebuild.nil?
          ptr = C.pkgcraft_config_repos_set(@config_ptr, 1)
          @_ebuild = Repo::RepoSet.send(:from_ptr, ptr)
        end
        @_ebuild
      end

      def each(&block)
        @repos.values.each(&block)
      end

      def length
        @repos.length
      end

      def [](val)
        @repos[val]
      end

      def to_s
        @repos.to_s
      end
    end
  end
end
