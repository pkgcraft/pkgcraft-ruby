# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for error related functionality
  module C
    # Wrapper for errors
    class Error < FFI::ManagedStruct
      layout :message, :string,
             :kind, :int

      def self.release(ptr)
        C.pkgcraft_error_free(ptr)
      end
    end

    attach_function :pkgcraft_error_last, [], Error.by_ref
    attach_function :pkgcraft_error_free, [:pointer], :void
  end

  # Error support
  module Error
    # Generic pkgcraft error
    class PkgcraftError < StandardError
      def initialize(msg = nil)
        if msg.nil?
          err = C.pkgcraft_error_last
          raise "no pkgcraft error occurred" if err.null?

          msg = err[:message]
        end

        super(msg)
      end
    end

    class ConfigError < PkgcraftError; end
    class InvalidCpn < PkgcraftError; end
    class InvalidCpv < PkgcraftError; end
    class InvalidDep < PkgcraftError; end
    class InvalidRepo < PkgcraftError; end
    class InvalidRestrict < PkgcraftError; end
    class InvalidVersion < PkgcraftError; end
  end
end
