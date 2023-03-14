# frozen_string_literal: true

require "set"

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

  # TODO: use shared toml test data
  def test_intersects
    # equal
    cpv1 = Pkgcraft::Dep::Cpv.new("cat/pkg-1")
    cpv2 = Pkgcraft::Dep::Cpv.new("cat/pkg-1-r0")
    assert(cpv1.intersects(cpv2))

    # dep
    cpv = Pkgcraft::Dep::Cpv.new("cat/pkg-1")
    dep = Pkgcraft::Dep::Dep.new("=cat/pkg-1-r0")
    assert(cpv.intersects(dep))

    # unequal
    cpv1 = Pkgcraft::Dep::Cpv.new("cat/pkg-1")
    cpv2 = Pkgcraft::Dep::Cpv.new("cat/pkg-1.0")
    assert(!cpv1.intersects(cpv2))
  end

  # TODO: use shared toml test data
  def test_hash
    # equal
    cpv1 = Pkgcraft::Dep::Cpv.new("cat/pkg-1")
    cpv2 = Pkgcraft::Dep::Cpv.new("cat/pkg-1-r0")
    cpvs = Set.new([cpv1, cpv2])
    assert_equal(cpvs.length, 1)

    # unequal
    cpv1 = Pkgcraft::Dep::Cpv.new("cat/pkg-1")
    cpv2 = Pkgcraft::Dep::Cpv.new("cat/pkg-1.0")
    cpvs = Set.new([cpv1, cpv2])
    assert_equal(cpvs.length, 2)
  end
end
