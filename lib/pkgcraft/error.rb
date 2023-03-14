# frozen_string_literal: true

module Pkgcraft
  class Error < StandardError; end
  class InvalidCpv < Error; end
  class InvalidDep < Error; end
  class InvalidVersion < Error; end
end
