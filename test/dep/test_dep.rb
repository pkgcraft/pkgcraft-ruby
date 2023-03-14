# frozen_string_literal: true

require "set"

require "test_helper"

class TestDep < Minitest::Test
  def test_new
    # revision
    dep1 = Pkgcraft::Dep::Dep.new("=cat/pkg-1-r2")
    assert_equal(dep1.category, "cat")
    assert_equal(dep1.package, "pkg")
    assert_equal(dep1.version, Pkgcraft::Dep::VersionWithOp.new("=1-r2"))
    assert_equal(dep1.revision, "2")
    assert_equal(dep1.p, "pkg-1")
    assert_equal(dep1.pf, "pkg-1-r2")
    assert_equal(dep1.pr, "r2")
    assert_equal(dep1.pv, "1")
    assert_equal(dep1.pvr, "1-r2")
    assert_equal(dep1.cpn, "cat/pkg")
    assert_equal(dep1.cpv, "cat/pkg-1-r2")
    assert_equal(dep1.to_s, "=cat/pkg-1-r2")

    # no revision
    dep2 = Pkgcraft::Dep::Dep.new("=cat/pkg-2")
    assert_nil(dep2.revision)
    assert_equal(dep2.p, "pkg-2")
    assert_equal(dep2.pf, "pkg-2")
    assert_equal(dep2.pr, "r0")
    assert_equal(dep2.pv, "2")
    assert_equal(dep2.pvr, "2")
    assert_equal(dep2.cpn, "cat/pkg")
    assert_equal(dep2.cpv, "cat/pkg-2")
    assert_equal(dep2.to_s, "=cat/pkg-2")
    assert(dep1 < dep2)

    # no version
    dep = Pkgcraft::Dep::Dep.new("cat/pkg")
    assert_nil(dep.version)
    assert_nil(dep.revision)
    assert_equal(dep.p, "pkg")
    assert_equal(dep.pf, "pkg")
    assert_nil(dep.pr)
    assert_nil(dep.pv)
    assert_nil(dep.pvr)
    assert_equal(dep.cpn, "cat/pkg")
    assert_equal(dep.cpv, "cat/pkg")
    assert_equal(dep.to_s, "cat/pkg")

    # invalid
    assert_raises RuntimeError do
      Pkgcraft::Dep::Dep.new("cat/pkg-1")
    end
  end

  # TODO: use shared toml test data
  def test_intersects
    # equal
    dep1 = Pkgcraft::Dep::Dep.new("=cat/pkg-1")
    dep2 = Pkgcraft::Dep::Dep.new("=cat/pkg-1-r0")
    assert(dep1.intersects(dep2))

    # cpv
    dep = Pkgcraft::Dep::Dep.new("=cat/pkg-1-r0")
    cpv = Pkgcraft::Dep::Cpv.new("cat/pkg-1")
    assert(dep.intersects(cpv))

    # unequal
    dep1 = Pkgcraft::Dep::Dep.new("=cat/pkg-1")
    dep2 = Pkgcraft::Dep::Dep.new("=cat/pkg-1.0")
    assert(!dep1.intersects(dep2))
  end

  # TODO: use shared toml test data
  def test_hash
    # equal
    dep1 = Pkgcraft::Dep::Dep.new("=cat/pkg-1")
    dep2 = Pkgcraft::Dep::Dep.new("=cat/pkg-1-r0")
    deps = Set.new([dep1, dep2])
    assert_equal(deps.length, 1)

    # unequal
    dep1 = Pkgcraft::Dep::Dep.new("=cat/pkg-1")
    dep2 = Pkgcraft::Dep::Dep.new("=cat/pkg-1.0")
    deps = Set.new([dep1, dep2])
    assert_equal(deps.length, 2)
  end
end
