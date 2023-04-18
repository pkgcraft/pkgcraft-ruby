# frozen_string_literal: true

require "set"

require "test_helper"

class TestDep < Minitest::Test
  include Pkgcraft
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
    assert_includes(dep1.inspect, "=cat/pkg-1-r2")

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
    assert_includes(dep2.inspect, "=cat/pkg-2")

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
    assert_includes(dep.inspect, "cat/pkg")

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
    assert_includes(dep.inspect, "!!>=cat/pkg-1-r2:0/2=[a,b,c]::repo")

    # explicitly specifying an official EAPI fails
    ["8", EAPI8].each do |eapi|
      assert_raises InvalidDep do
        Dep.new("cat/pkg::repo", eapi)
      end
    end

    # invalid
    ["cat/pkg-1", "", nil].each do |s|
      assert_raises InvalidDep do
        Dep.new(s)
      end
    end
  end

  def optional_value(expected, value)
    if expected.nil?
      assert_nil(value)
    else
      assert_equal(expected, value)
    end
  end

  def test_parse
    TESTDATA_TOML["dep"]["valid"].each do |d|
      s = d["dep"]
      passing_eapis = Set.new(Eapis.range(d["eapis"]))
      EAPIS.each_value do |eapi|
        if passing_eapis.include?(eapi)
          dep = Dep.new(s, eapi)
          assert_equal(d["category"], dep.category)
          assert_equal(d["package"], dep.package)
          if d["blocker"].nil?
            assert_nil(dep.blocker)
          else
            assert_equal(Blocker.from_str(d["blocker"]), dep.blocker)
          end
          if d["version"].nil?
            assert_nil(dep.version)
          else
            assert_equal(VersionWithOp.new(d["version"]), dep.version)
          end
          optional_value(d["revision"], dep.revision)
          optional_value(d["slot"], dep.slot)
          optional_value(d["subslot"], dep.subslot)
          if d["slot_op"].nil?
            assert_nil(dep.slot_op)
          else
            assert_equal(SlotOperator.from_str(d["slot_op"]), dep.slot_op)
          end
          optional_value(d["use"], dep.use)
          optional_value(d["repo"], dep.repo)
          assert_equal(s, dep.to_s)
          assert_includes(dep.inspect, s)
        else
          assert_raises InvalidDep do
            Dep.new(s, eapi)
          end
        end
      end
    end

    TESTDATA_TOML["dep"]["invalid"].each do |s|
      EAPIS.each_value do |eapi|
        assert_raises InvalidDep do
          Dep.new(s, eapi)
        end
      end
    end
  end

  def test_cmp
    TESTDATA_TOML["dep"]["compares"].each do |s|
      s1, op, s2 = s.split
      d1 = Dep.new(s1)
      d2 = Dep.new(s2)
      assert(d1.public_send(op, d2))
    end

    # invalid type
    dep = Dep.new("=cat/pkg-1")
    assert_raises TypeError do
      assert(dep < "=cat/pkg-1")
    end

    TESTDATA_TOML["version"]["compares"].each do |s|
      s1, op, s2 = s.split
      d1 = Dep.new("=cat/pkg-#{s1}")
      d2 = Dep.new("=cat/pkg-#{s2}")
      assert(d1.public_send(op, d2))
    end
  end

  # Convert string to Dep falling back to Cpv.
  def parse(str)
    Dep.new(str)
  rescue InvalidDep
    Cpv.new(str)
  end

  def test_intersects
    TESTDATA_TOML["dep"]["intersects"].each do |d|
      d["vals"].combination(2).each do |s1, s2|
        obj1 = parse(s1)
        obj2 = parse(s2)

        # elements intersect themselves
        assert(obj1.intersects(obj1))
        assert(obj2.intersects(obj2))

        # intersects depending on status
        if d["status"]
          assert(obj1.intersects(obj2))
        else
          refute(obj1.intersects(obj2))
        end
      end
    end

    # invalid type
    dep = Dep.new("=cat/pkg-1")
    assert_raises TypeError do
      dep.intersects("=cat/pkg-1")
    end
  end

  def test_sort
    TESTDATA_TOML["dep"]["sorting"].each do |d|
      expected = d["sorted"].map { |s| Dep.new(s) }.compact
      reversed = expected.reverse
      ordered = reversed.sort
      # equal objects aren't sorted so reversing should restore original order
      ordered = ordered.reverse if d["equal"]
      assert_equal(ordered, expected)
    end
  end

  def test_hash
    TESTDATA_TOML["version"]["hashing"].each do |d|
      deps = Set.new(d["versions"].map { |s| Dep.new("=cat/pkg-#{s}") }.compact)
      length = d["equal"] ? 1 : d["versions"].length
      assert_equal(deps.length, length)
    end
  end
end
