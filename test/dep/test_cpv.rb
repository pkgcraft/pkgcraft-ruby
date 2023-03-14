# frozen_string_literal: true

require "set"

require "test_helper"

class TestCpv < Minitest::Test
  def test_new
    # revision
    cpv1 = Pkgcraft::Dep::Cpv.new("cat/pkg-1-r2")
    assert_equal(cpv1.category, "cat")
    assert_equal(cpv1.package, "pkg")
    assert_equal(cpv1.version, Pkgcraft::Dep::Version.new("1-r2"))
    assert_equal(cpv1.revision, "2")
    assert_equal(cpv1.p, "pkg-1")
    assert_equal(cpv1.pf, "pkg-1-r2")
    assert_equal(cpv1.pr, "r2")
    assert_equal(cpv1.pv, "1")
    assert_equal(cpv1.pvr, "1-r2")
    assert_equal(cpv1.cpn, "cat/pkg")
    assert_equal(cpv1.to_s, "cat/pkg-1-r2")

    # no revision
    cpv2 = Pkgcraft::Dep::Cpv.new("cat/pkg-2")
    assert_nil(cpv2.revision)
    assert_equal(cpv2.p, "pkg-2")
    assert_equal(cpv2.pf, "pkg-2")
    assert_equal(cpv2.pr, "r0")
    assert_equal(cpv2.pv, "2")
    assert_equal(cpv2.pvr, "2")
    assert_equal(cpv2.cpn, "cat/pkg")
    assert_equal(cpv2.to_s, "cat/pkg-2")
    assert(cpv1 < cpv2)

    # invalid
    assert_raises Pkgcraft::InvalidCpv do
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

    # invalid type
    assert_raises TypeError do
      cpv1.intersects("cat/pkg-1")
    end
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
