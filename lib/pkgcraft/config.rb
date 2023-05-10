# frozen_string_literal: true

require "pathname"

module Pkgcraft
  # FFI bindings for Config related functionality
  module C
    # Wrapper for Config pointers
    class Config < AutoPointer
      def self.release(ptr)
        C.pkgcraft_config_free(ptr)
      end
    end

    attach_function :pkgcraft_config_new, [], Config
    attach_function :pkgcraft_config_free, [:pointer], :void
    attach_function :pkgcraft_config_load, [Config], :pointer
    attach_function :pkgcraft_config_load_portage_conf, [Config, :string], :pointer
    attach_function :pkgcraft_config_repos, [Config, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_config_repos_set, [Config, :int], Pkgcraft::Repos::RepoSet
    attach_function :pkgcraft_config_add_repo, [Config, :repo], :repo
    attach_function :pkgcraft_config_add_repo_path, [Config, :string, :int, :string], :repo
  end

  # Config support
  module Configs
    # Convert an array of repo pointers to a mapping.
    def self.repos_to_dict(repos_ptr, length, ref)
      c_repos = repos_ptr.get_array_of_pointer(0, length)
      repos = {}
      c_repos.each do |ptr|
        repo = Pkgcraft::Repos::Repo.send(:from_ptr, ptr, ref)
        repos[repo.id] = repo
      end
      repos
    end

    private_class_method :repos_to_dict

    # Config for the system.
    class Config < C::Config
      include InspectPointer
      include Pkgcraft::Repos

      def initialize
        @ptr = C.pkgcraft_config_new
      end

      def repos
        @repos = Repos.new(self) if @repos.nil?
        @repos
      end

      def load
        ptr = C.pkgcraft_config_load(self)
        raise Error::PkgcraftError if ptr.null?

        # force repos attr refresh
        @repos = nil
      end

      def load_portage_conf(path = nil)
        ptr = C.pkgcraft_config_load_portage_conf(self, path)
        raise Error::PkgcraftError if ptr.null?

        # force repos attr refresh
        @repos = nil
      end

      def add_repo(repo, id: nil, priority: 0)
        if [String, Pathname].any? { |c| repo.is_a? c }
          path = repo.to_s
          add_repo_path(path, id, priority)
        elsif repo.is_a? Repo
          ptr = C.pkgcraft_config_add_repo(self, repo.ptr)
          raise Error::ConfigError if ptr.null?

          @repos = nil
          repo
        else
          raise TypeError.new("unsupported repo type: #{repo.class}")
        end
      end

      private

      def add_repo_path(path, id, priority)
        path = path.to_s
        id = id.nil? ? path : id.to_s
        ptr = C.pkgcraft_config_add_repo_path(self, id, priority, path)
        raise Error::PkgcraftError if ptr.null?

        # force repos attr refresh
        @repos = nil

        Pkgcraft::Repos::Repo.send(:from_ptr, ptr, false)
      end
    end

    # System repositories.
    class Repos
      include Enumerable

      def initialize(config)
        length = C::LenPtr.new
        c_repos = C.pkgcraft_config_repos(config, length)
        @repos = Configs.send(:repos_to_dict, c_repos, length[:value], true)
        C.pkgcraft_array_free(c_repos, length[:value])
        @config = config
      end

      def all
        @all = C.pkgcraft_config_repos_set(@config, 0) if @all.nil?
        @all
      end

      def ebuild
        @ebuild = C.pkgcraft_config_repos_set(@config, 1) if @ebuild.nil?
        @ebuild
      end

      def each(&block)
        @repos.values.each(&block)
      end

      def key?(key)
        @repos.key?(key)
      end

      def empty?
        @repos.empty?
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

    private_constant :Repos
  end
end
