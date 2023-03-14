# frozen_string_literal: true

module Pkgcraft
  # Generic pkgcraft error
  class Error < StandardError
    def initialize(msg = nil)
      if msg.nil?
        err = C.pkgcraft_error_last
        raise "no pkgcraft-c error occurred" if err.null?

        msg = err[:message]
        C.pkgcraft_error_free(err)
      end

      super(msg)
    end
  end

  class InvalidCpv < Error; end
  class InvalidDep < Error; end
  class InvalidVersion < Error; end
end
