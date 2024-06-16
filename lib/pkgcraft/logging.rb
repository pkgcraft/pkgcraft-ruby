# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for logging related functionality
  module C
    LogLevel = enum(
      :OFF, 0,
      :TRACE,
      :DEBUG,
      :INFO,
      :WARN,
      :ERROR
    )

    # Wrapper for log messages
    class PkgcraftLog < FFI::ManagedStruct
      layout :message, :string,
             :level, LogLevel

      def self.release(ptr)
        C.pkgcraft_log_free(ptr)
      end
    end

    callback :log_callback, [PkgcraftLog.by_ref], :void
    attach_function :pkgcraft_log_free, [:pointer], :void
    attach_function :pkgcraft_log_test, [:string, LogLevel], :void
    attach_function :pkgcraft_logging_enable, [:log_callback, LogLevel], :void
  end

  # Logging support
  module Logging
    require "logger"

    def self.convert_level(level)
      case level
      when Logger::DEBUG
        C::LogLevel[:DEBUG]
      when Logger::INFO
        C::LogLevel[:INFO]
      when Logger::WARN
        C::LogLevel[:WARN]
      when Logger::ERROR
        C::LogLevel[:ERROR]
      else
        C::LogLevel[:OFF]
      end
    end

    private_class_method :convert_level

    LogCallback = proc do |log|
      msg = log[:message]

      case log[:level]
      when :DEBUG, :TRACE
        @logger.debug(msg)
      when :INFO
        @logger.info(msg)
      when :WARN
        @logger.warn(msg)
      when :ERROR
        @logger.error(msg)
      end
    end

    private_constant :LogCallback

    # Inject log messages into pkgcraft to replay for test purposes.
    def self.log_test(message, level)
      C.pkgcraft_log_test(message, convert_level(level))
    end

    # Custom logger that supports switching pkgcraft log levels.
    class PkgcraftLogger < Logger
      def level=(severity)
        level = Logging.send(:convert_level, severity)
        C.pkgcraft_logging_enable(LogCallback, level)
        super(severity)
      end
    end

    # disable logging output by default
    @logger = PkgcraftLogger.new($stderr, level: -1)

    def self.logger
      @logger
    end
  end
end
