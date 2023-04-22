# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for logging related functionality
  module C
    LogLevel = enum(
      :TRACE, 0,
      :DEBUG,
      :INFO,
      :WARN,
      :ERROR
    )

    # Wrapper for log messages
    class PkgcraftLog < FFI::Struct
      layout :message, :string,
             :level, LogLevel
    end

    callback :log_callback, [PkgcraftLog.by_ref], :void
    attach_function :pkgcraft_logging_enable, [:log_callback, LogLevel], :void
    attach_function :pkgcraft_log_free, [:pointer], :void
    attach_function :pkgcraft_log_test, [:string, LogLevel], :void
  end

  # Logging support
  module Logging
    require "logger"

    @logger = Logger.new($stderr)

    LogCallback = proc do |log|
      msg = log[:message]

      case log[:level]
      when :TRACE, :DEBUG
        @logger.debug(msg)
      when :INFO
        @logger.info(msg)
      when :WARN
        @logger.warn(msg)
      when :ERROR
        @logger.error(msg)
      else
        raise "unknown log level: #{log[:level]}"
      end

      C.pkgcraft_log_free(log)
    end

    private_constant :LogCallback

    # Set a custom log level for pkgcraft.
    def self.enable(level = 3)
      levels = C::LogLevel.symbol_map.values
      raise "Invalid log level: #{level}" unless levels.include? level

      C.pkgcraft_logging_enable(LogCallback, C::LogLevel[level])
    end

    # Inject log messages into pkgcraft to replay for test purposes.
    def self.log_test(message, level)
      levels = C::LogLevel.symbol_map.values
      raise "Invalid log level: #{level}" unless levels.include? level

      C.pkgcraft_log_test(message, C::LogLevel[level])
    end
  end
end
