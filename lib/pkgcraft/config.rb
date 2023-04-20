# frozen_string_literal: true

require "pathname"

module Pkgcraft
  # Config support
  module Configs
    PORTAGE_REPOS_CONF_DEFAULTS = [
      "/etc/portage/repos.conf",
      "/usr/share/portage/config.repos.conf"
    ].freeze

    private_constant :PORTAGE_REPOS_CONF_DEFAULTS

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
      include Pkgcraft::Repos

      def initialize
        @ptr = C.pkgcraft_config_new
      end

      def repos
        @repos = Repos.send(:from_ptr, @ptr) if @repos.nil?
        @repos
      end

      def load_repos_conf(path = nil, defaults: PORTAGE_REPOS_CONF_DEFAULTS)
        length = C::LenPtr.new
        if path.nil?
          defaults.each do |p|
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
        @repos = nil

        repos = Configs.send(:repos_to_dict, c_repos, length[:value], false)
        C.pkgcraft_repos_free(c_repos, length[:value])
        repos
      end

      def add_repo(repo, id: nil, priority: 0)
        if [String, Pathname].any? { |c| repo.is_a? c }
          path = repo.to_s
          add_repo_path(path, id, priority)
        elsif repo.is_a? Repo
          ptr = C.pkgcraft_config_add_repo(@ptr, repo.ptr)
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
        ptr = C.pkgcraft_config_add_repo_path(@ptr, id, priority, path)
        raise Error::PkgcraftError if ptr.null?

        # force repos attr refresh
        @repos = nil

        Pkgcraft::Repos::Repo.send(:from_ptr, ptr, false)
      end
    end

    # System repositories.
    class Repos
      include Enumerable

      # Create a Repos object from a Config pointer.
      def self.from_ptr(ptr)
        length = C::LenPtr.new
        c_repos = C.pkgcraft_config_repos(ptr, length)
        repos = Configs.send(:repos_to_dict, c_repos, length[:value], true)
        C.pkgcraft_repos_free(c_repos, length[:value])

        obj = allocate
        obj.instance_variable_set(:@config_ptr, ptr)
        obj.instance_variable_set(:@repos, repos)
        obj
      end

      private_class_method :from_ptr

      def all
        @all = C.pkgcraft_config_repos_set(@config_ptr, 0) if @all.nil?
        @all
      end

      def ebuild
        @ebuild = C.pkgcraft_config_repos_set(@config_ptr, 1) if @ebuild.nil?
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
  end

  # FFI bindings for config related functionality
  module C
    # Wrapper for config objects
    class Config < FFI::AutoPointer
      def self.release(ptr)
        C.pkgcraft_config_free(ptr)
      end
    end

    # config support
    attach_function :pkgcraft_config_new, [], Config
    attach_function :pkgcraft_config_free, [:pointer], :void
    attach_function :pkgcraft_config_load_repos_conf, [Config, :string, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_config_repos, [Config, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_config_repos_set, [Config, :int], Pkgcraft::Repos::RepoSet
    attach_function :pkgcraft_config_add_repo, [Config, :repo], :repo
    attach_function :pkgcraft_config_add_repo_path, [Config, :string, :int, :string], :repo
  end
end
