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
    assert_equal(dep1.category, "cat")
    assert_equal(dep1.package, "pkg")
    assert_equal(dep1.version, VersionWithOp.new("=1-r2"))
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
    dep2 = Dep.new("=cat/pkg-2")
    assert_nil(dep2.revision)
    assert_equal(dep2.p, "pkg-2")
    assert_equal(dep2.pf, "pkg-2")
    assert_equal(dep2.pr, "r0")
    assert_equal(dep2.pv, "2")
    assert_equal(dep2.pvr, "2")
    assert_equal(dep2.cpn, "cat/pkg")
    assert_equal(dep2.cpv, "cat/pkg-2")
    assert_equal(dep2.to_s, "=cat/pkg-2")

    # no version
    dep = Dep.new("cat/pkg")
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

    # all fields -- extended EAPI default allows repo deps
    dep = Dep.new("!!>=cat/pkg-1-r2:0/2=[a,b,c]::repo")
    assert dep.category == "cat"
    assert dep.package == "pkg"
    # assert dep.blocker == Blocker.Strong
    # assert dep.blocker == "!!"
    # assert dep.slot == "0"
    # assert dep.subslot == "2"
    # assert dep.slot_op == SlotOperator.Equal
    # assert dep.slot_op == "="
    # assert dep.use == ("a", "b", "c")
    # assert dep.repo == "repo"
    assert dep.version == VersionWithOp.new(">=1-r2")
    # assert dep.op == Operator.GreaterOrEqual
    # assert dep.op == ">="
    assert dep.revision == "2"
    assert dep.p == "pkg-1"
    assert dep.pf == "pkg-1-r2"
    assert dep.pr == "r2"
    assert dep.pv == "1"
    assert dep.pvr == "1-r2"
    assert dep.cpn == "cat/pkg"
    assert dep.cpv == "cat/pkg-1-r2"
    assert dep.to_s == "!!>=cat/pkg-1-r2:0/2=[a,b,c]::repo"

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
    assert(!dep1.intersects(dep2))

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
    assert_equal(deps.length, 1)

    # unequal
    dep1 = Dep.new("=cat/pkg-1")
    dep2 = Dep.new("=cat/pkg-1.0")
    deps = Set.new([dep1, dep2])
    assert_equal(deps.length, 2)
  end
end
