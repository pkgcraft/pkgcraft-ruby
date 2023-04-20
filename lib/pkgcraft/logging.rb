# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for logging related functionality
  module C
    # Wrapper for log messages
    class PkgcraftLog < FFI::ManagedStruct
      layout :message, :string,
             :level, :int

      def self.release(ptr)
        C.pkgcraft_log_free(ptr)
      end
    end

    callback :log_callback, [PkgcraftLog.by_ref], :void
    attach_function :pkgcraft_logging_enable, [:log_callback], :void
    attach_function :pkgcraft_log_free, [:pointer], :void
    attach_function :pkgcraft_log_test, [PkgcraftLog.by_ref], :void
  end

  # Logging support
  module Logging
    require "logger"

    LOG = Logger.new($stderr)
    private_constant :LOG

    LogCallback = proc do |log|
      msg = log[:message]

      case log[:level]
      when 0..1
        LOG.debug(msg)
      when 2
        LOG.info(msg)
      when 3
        LOG.warn(msg)
      else
        LOG.error(msg)
      end
    end

    private_constant :LogCallback

    # Enable forwarding pkgcraft logs into ruby's log system.
    def self.enable
      C.pkgcraft_logging_enable(LogCallback)
    end
  end
end
