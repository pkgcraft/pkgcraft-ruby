# frozen_string_literal: true

require "set"

require "test_helper"

class TestCpv < Minitest::Test
  include Pkgcraft::Dep
  include Pkgcraft::Error

  def test_new
    # revision
    cpv1 = Cpv.new("cat/pkg-1-r2")
    assert_equal("cat", cpv1.category)
    assert_equal("pkg", cpv1.package)
    assert_equal(cpv1.version, Version.new("1-r2"))
    assert_equal("2", cpv1.revision)
    assert_equal("pkg-1", cpv1.p)
    assert_equal("pkg-1-r2", cpv1.pf)
    assert_equal("r2", cpv1.pr)
    assert_equal("1", cpv1.pv)
    assert_equal("1-r2", cpv1.pvr)
    assert_equal("cat/pkg", cpv1.cpn)
    assert_equal("cat/pkg-1-r2", cpv1.to_s)

    # no revision
    cpv2 = Cpv.new("cat/pkg-2")
    assert_nil(cpv2.revision)
    assert_equal("pkg-2", cpv2.p)
    assert_equal("pkg-2", cpv2.pf)
    assert_equal("r0", cpv2.pr)
    assert_equal("2", cpv2.pv)
    assert_equal("2", cpv2.pvr)
    assert_equal("cat/pkg", cpv2.cpn)
    assert_equal("cat/pkg-2", cpv2.to_s)
    assert(cpv1 < cpv2)

    # invalid
    assert_raises InvalidCpv do
      Cpv.new("=cat/pkg-1")
    end
  end

  # TODO: use shared toml test data
  def test_intersects
    # equal
    cpv1 = Cpv.new("cat/pkg-1")
    cpv2 = Cpv.new("cat/pkg-1-r0")
    assert(cpv1.intersects(cpv2))

    # dep
    cpv = Cpv.new("cat/pkg-1")
    dep = Dep.new("=cat/pkg-1-r0")
    assert(cpv.intersects(dep))

    # unequal
    cpv1 = Cpv.new("cat/pkg-1")
    cpv2 = Cpv.new("cat/pkg-1.0")
    refute(cpv1.intersects(cpv2))

    # invalid type
    assert_raises TypeError do
      cpv1.intersects("cat/pkg-1")
    end
  end

  # TODO: use shared toml test data
  def test_hash
    # equal
    cpv1 = Cpv.new("cat/pkg-1")
    cpv2 = Cpv.new("cat/pkg-1-r0")
    cpvs = Set.new([cpv1, cpv2])
    assert_equal(1, cpvs.length)

    # unequal
    cpv1 = Cpv.new("cat/pkg-1")
    cpv2 = Cpv.new("cat/pkg-1.0")
    cpvs = Set.new([cpv1, cpv2])
    assert_equal(2, cpvs.length)
  end
end
