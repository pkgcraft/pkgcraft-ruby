# frozen_string_literal: true

require "test_helper"

class TestLogging < Minitest::Test
  include Pkgcraft

  def test_simple
    # matching level outputs
    Logging.enable(3)
    _, err = capture_subprocess_io do
      Logging.log_test("pkgcraft", 3)
    end
    refute_empty(err)

    # lower level skips output
    _, err = capture_subprocess_io do
      Logging.log_test("pkgcraft", 2)
    end
    assert_empty(err)

    # higher level outputs
    _, err = capture_subprocess_io do
      Logging.log_test("pkgcraft", 4)
    end
    refute_empty(err)

    # disable all logging
    Logging.enable(0)
  end
end
