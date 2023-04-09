# frozen_string_literal: true

module Pkgcraft
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

      C.pkgcraft_log_free(log)
    end

    private_constant :LogCallback

    C.pkgcraft_logging_enable(LogCallback)
  end
end
