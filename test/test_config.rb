# frozen_string_literal: true

require "test_helper"

class TestConfig < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Config
  include Pkgcraft::Error

  def test_new
    config = Config.new
    assert_equal(0, config.repos.length)
  end
end
