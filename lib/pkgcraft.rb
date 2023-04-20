# frozen_string_literal: true

module Pkgcraft
  # singleton used as default for cached values allowed to be nil
  SENTINEL = Object.new.freeze
  private_constant :SENTINEL
end

require_relative "pkgcraft/bindings"
require_relative "pkgcraft/eapi"
require_relative "pkgcraft/error"
require_relative "pkgcraft/restrict"
require_relative "pkgcraft/dep"
require_relative "pkgcraft/pkg"
require_relative "pkgcraft/repo"
require_relative "pkgcraft/config"
require_relative "pkgcraft/logging"
require_relative "pkgcraft/version"
