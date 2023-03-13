# frozen_string_literal: true

require "test_helper"

class TestCpv < Minitest::Test
  def test_new
    # valid
    cpv = Pkgcraft::Dep::Cpv.new("cat/pkg-1")
    assert_equal(cpv.category, "cat")
    assert_equal(cpv.package, "pkg")

    # invalid
    assert_raises RuntimeError do
      Pkgcraft::Dep::Cpv.new("=cat/pkg-1")
    end
  end
end
