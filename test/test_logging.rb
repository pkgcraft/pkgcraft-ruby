# frozen_string_literal: true

require "test_helper"

class TestLogging < Minitest::Test
  include Pkgcraft

  def test_simple
    [Logger::DEBUG, Logger::INFO, Logger::WARN, Logger::ERROR].each do |level|
      Logging.logger.level = level
      _, err = capture_subprocess_io do
        Logging.log_test("pkgcraft", level)
      end
      refute_empty(err)

      # setting a higher level filters the message
      Logging.logger.level = level + 1
      _, err = capture_subprocess_io do
        Logging.log_test("pkgcraft", level)
      end
      assert_empty(err)

      # setting a lower level passes the message, except when 0 since -1 disables logging
      next unless level.positive?

      Logging.logger.level = level - 1
      _, err = capture_subprocess_io do
        Logging.log_test("pkgcraft", level)
      end
      refute_empty(err)
    end

    # disable all logging
    Logging.logger.level = -1
  end
end
