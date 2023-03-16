# frozen_string_literal: true

require "set"

require "test_helper"

class TestDep < Minitest::Test
  include Pkgcraft::Dep
  include Pkgcraft::Eapis
  include Pkgcraft::Error

  def test_new
    # revision
    dep1 = Dep.new("=cat/pkg-1-r2")
    assert_equal("cat", dep1.category)
    assert_equal("pkg", dep1.package)
    assert_equal(dep1.version, VersionWithOp.new("=1-r2"))
    assert_equal("2", dep1.revision)
    assert_equal("pkg-1", dep1.p)
    assert_equal("pkg-1-r2", dep1.pf)
    assert_equal("r2", dep1.pr)
    assert_equal("1", dep1.pv)
    assert_equal("1-r2", dep1.pvr)
    assert_equal("cat/pkg", dep1.cpn)
    assert_equal("cat/pkg-1-r2", dep1.cpv)
    assert_equal("=cat/pkg-1-r2", dep1.to_s)

    # no revision
    dep2 = Dep.new("=cat/pkg-2")
    assert_nil(dep2.revision)
    assert_equal("pkg-2", dep2.p)
    assert_equal("pkg-2", dep2.pf)
    assert_equal("r0", dep2.pr)
    assert_equal("2", dep2.pv)
    assert_equal("2", dep2.pvr)
    assert_equal("cat/pkg", dep2.cpn)
    assert_equal("cat/pkg-2", dep2.cpv)
    assert_equal("=cat/pkg-2", dep2.to_s)

    # no version
    dep = Dep.new("cat/pkg")
    assert_nil(dep.version)
    assert_nil(dep.revision)
    assert_equal("pkg", dep.p)
    assert_equal("pkg", dep.pf)
    assert_nil(dep.pr)
    assert_nil(dep.pv)
    assert_nil(dep.pvr)
    assert_equal("cat/pkg", dep.cpn)
    assert_equal("cat/pkg", dep.cpv)
    assert_equal("cat/pkg", dep.to_s)

    # all fields -- extended EAPI default allows repo deps
    dep = Dep.new("!!>=cat/pkg-1-r2:0/2=[a,b,c]::repo")
    assert_equal("cat", dep.category)
    assert_equal("pkg", dep.package)
    assert_equal(Blocker::Strong, dep.blocker)
    assert_equal("0", dep.slot)
    assert_equal("2", dep.subslot)
    assert_equal(SlotOperator::Equal, dep.slot_op)
    assert_equal(["a", "b", "c"], dep.use)
    assert_equal("repo", dep.repo)
    assert_equal(dep.version, VersionWithOp.new(">=1-r2"))
    assert_equal(Operator::GreaterOrEqual, dep.op)
    assert_equal("2", dep.revision)
    assert_equal("pkg-1", dep.p)
    assert_equal("pkg-1-r2", dep.pf)
    assert_equal("r2", dep.pr)
    assert_equal("1", dep.pv)
    assert_equal("1-r2", dep.pvr)
    assert_equal("cat/pkg", dep.cpn)
    assert_equal("cat/pkg-1-r2", dep.cpv)
    assert_equal("!!>=cat/pkg-1-r2:0/2=[a,b,c]::repo", dep.to_s)

    # explicitly specifying an official EAPI fails
    ["8", EAPI8].each do |eapi|
      assert_raises InvalidDep do
        Dep.new("cat/pkg::repo", eapi)
      end
    end

    # invalid
    assert_raises InvalidDep do
      Dep.new("cat/pkg-1")
    end
  end

  # TODO: use shared toml test data
  def test_intersects
    # equal
    dep1 = Dep.new("=cat/pkg-1")
    dep2 = Dep.new("=cat/pkg-1-r0")
    assert(dep1.intersects(dep2))

    # cpv
    dep = Dep.new("=cat/pkg-1-r0")
    cpv = Cpv.new("cat/pkg-1")
    assert(dep.intersects(cpv))

    # unequal
    dep1 = Dep.new("=cat/pkg-1")
    dep2 = Dep.new("=cat/pkg-1.0")
    refute(dep1.intersects(dep2))

    # invalid type
    assert_raises TypeError do
      dep1.intersects("=cat/pkg-1")
    end
  end

  def test_cmp
    TOML["dep"]["compares"].each do |s|
      s1, op, s2 = s.split
      d1 = Dep.new(s1)
      d2 = Dep.new(s2)
      assert(d1.public_send(op, d2))
    end

    TOML["version"]["compares"].each do |s|
      s1, op, s2 = s.split
      d1 = Dep.new("=cat/pkg-#{s1}")
      d2 = Dep.new("=cat/pkg-#{s2}")
      assert(d1.public_send(op, d2))
    end
  end

  # TODO: use shared toml test data
  def test_hash
    # equal
    dep1 = Dep.new("=cat/pkg-1")
    dep2 = Dep.new("=cat/pkg-1-r0")
    deps = Set.new([dep1, dep2])
    assert_equal(1, deps.length)

    # unequal
    dep1 = Dep.new("=cat/pkg-1")
    dep2 = Dep.new("=cat/pkg-1.0")
    deps = Set.new([dep1, dep2])
    assert_equal(2, deps.length)
  end
end
