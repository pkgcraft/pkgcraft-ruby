# frozen_string_literal: true

require "set"

require "test_helper"

class TestDep < Minitest::Test
  def test_new
    # valid
    dep1 = Pkgcraft::Dep::Dep.new("=cat/pkg-1")
    assert_equal(dep1.category, "cat")
    assert_equal(dep1.package, "pkg")
    assert_equal(dep1.version, Pkgcraft::Dep::VersionWithOp.new("=1"))
    assert_nil(dep1.revision)
    assert_equal(dep1.to_s, "=cat/pkg-1")

    dep2 = Pkgcraft::Dep::Dep.new("=cat/pkg-2")
    assert(dep1 < dep2)

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
