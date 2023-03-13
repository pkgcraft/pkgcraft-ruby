# frozen_string_literal: true

require "test_helper"

class TestCpv < Minitest::Test
  def test_new
    # valid
    cpv1 = Pkgcraft::Dep::Cpv.new("cat/pkg-1")
    assert_equal(cpv1.category, "cat")
    assert_equal(cpv1.package, "pkg")
    assert_equal(cpv1.version, Pkgcraft::Dep::Version.new("1"))
    assert_nil(cpv1.revision)
    assert_equal(cpv1.to_s, "cat/pkg-1")

    cpv2 = Pkgcraft::Dep::Cpv.new("cat/pkg-2")
    assert(cpv1 < cpv2)

    # invalid
    assert_raises RuntimeError do
      Pkgcraft::Dep::Cpv.new("=cat/pkg-1")
    end
  end
end
