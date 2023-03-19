# frozen_string_literal: true

module Pkgcraft
  # Error support
  module Error
    # Generic pkgcraft error
    class PkgcraftError < StandardError
      def initialize(msg = nil)
        if msg.nil?
          err = C.pkgcraft_error_last
          raise "no pkgcraft error occurred" if err.null?

          msg = err[:message]
          C.pkgcraft_error_free(err)
        end

        super(msg)
      end
    end

    class InvalidCpv < PkgcraftError; end
    class InvalidDep < PkgcraftError; end
    class InvalidVersion < PkgcraftError; end
  end
end
