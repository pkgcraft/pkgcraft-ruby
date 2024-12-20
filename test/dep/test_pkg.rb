# frozen_string_literal: true

require "set"

require "test_helper"

class TestDep < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Dep
  include Pkgcraft::Eapis
  include Pkgcraft::Error
  include Pkgcraft::Repos

  def test_new
    # revision
    dep = Dep.new("=cat/pkg-1-r2")
    assert_equal("cat", dep.category)
    assert_equal("pkg", dep.package)
    assert_equal(dep.version, Version.new("=1-r2"))
    assert_equal(Operator::Equal, dep.op)
    assert_equal(dep.revision, Revision.new("2"))
    assert_nil(dep.blocker)
    assert_nil(dep.slot)
    assert_nil(dep.subslot)
    assert_nil(dep.slot_op)
    assert_nil(dep.use)
    assert_nil(dep.repo)
    assert_equal(Cpn.new("cat/pkg"), dep.cpn)
    assert_equal(Cpv.new("cat/pkg-1-r2"), dep.cpv)
    assert_equal("=cat/pkg-1-r2", dep.to_s)
    assert_includes(dep.inspect, "=cat/pkg-1-r2")

    # no revision
    dep = Dep.new("=cat/pkg-2")
    assert_equal("cat", dep.category)
    assert_equal("pkg", dep.package)
    assert_equal(dep.version, Version.new("=2"))
    assert_equal(Operator::Equal, dep.op)
    assert_nil(dep.revision)
    assert_nil(dep.blocker)
    assert_nil(dep.slot)
    assert_nil(dep.subslot)
    assert_nil(dep.slot_op)
    assert_nil(dep.use)
    assert_nil(dep.repo)
    assert_equal(Cpn.new("cat/pkg"), dep.cpn)
    assert_equal(Cpv.new("cat/pkg-2"), dep.cpv)
    assert_equal("=cat/pkg-2", dep.to_s)
    assert_includes(dep.inspect, "=cat/pkg-2")

    # no version
    dep = Dep.new("cat/pkg")
    assert_nil(dep.version)
    assert_nil(dep.revision)
    assert_nil(dep.op)
    assert_nil(dep.blocker)
    assert_nil(dep.slot)
    assert_nil(dep.subslot)
    assert_nil(dep.slot_op)
    assert_nil(dep.use)
    assert_nil(dep.repo)
    assert_equal(Cpn.new("cat/pkg"), dep.cpn)
    assert_nil(dep.cpv)
    assert_equal("cat/pkg", dep.to_s)
    assert_includes(dep.inspect, "cat/pkg")

    # all fields -- extended EAPI default allows repo deps
    dep = Dep.new("!!>=cat/pkg-1-r2:0/2=::repo[a,b,c]")
    assert_equal("cat", dep.category)
    assert_equal("pkg", dep.package)
    assert_equal(dep.version, Version.new(">=1-r2"))
    assert_equal(dep.revision, Revision.new("2"))
    assert_equal(Operator::GreaterOrEqual, dep.op)
    assert_equal(Blocker::Strong, dep.blocker)
    assert_equal("0", dep.slot)
    assert_equal("2", dep.subslot)
    assert_equal(SlotOperator::Equal, dep.slot_op)
    assert_equal(["a", "b", "c"], dep.use)
    assert_equal("repo", dep.repo)
    assert_equal(Cpn.new("cat/pkg"), dep.cpn)
    assert_equal(Cpv.new("cat/pkg-1-r2"), dep.cpv)
    assert_equal("!!>=cat/pkg-1-r2:0/2=::repo[a,b,c]", dep.to_s)
    assert_includes(dep.inspect, "!!>=cat/pkg-1-r2:0/2=::repo[a,b,c]")

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

  def test_unversioned
    # no change returns the same object
    dep1 = Dep.new("cat/pkg")
    assert_same(dep1, dep1.unversioned)

    dep2 = Dep.new("=cat/pkg-1-r2")
    assert_equal(dep2.unversioned, dep1)
  end

  def test_versioned
    # no change returns the same object
    dep1 = Dep.new("=cat/pkg-1")
    assert_same(dep1, dep1.versioned)

    dep2 = Dep.new(">=cat/pkg-1:2/3[a,!b?]")
    assert_equal(dep2.versioned, dep1)
  end

  def test_no_use_deps
    # no change returns the same object
    dep1 = Dep.new(">=cat/pkg-1-r2:3/4")
    assert_same(dep1, dep1.no_use_deps)

    dep2 = Dep.new(">=cat/pkg-1-r2:3/4[a,!b?]")
    assert_equal(dep2.no_use_deps, dep1)
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
          assert(Dep.parse(s, eapi))
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
            assert_equal(Version.new(d["version"]), dep.version)
          end
          if d["revision"].nil?
            assert_nil(dep.revision)
          else
            assert_equal(Revision.new(d["revision"]), dep.revision)
          end
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
          refute(Dep.parse(s, eapi))
          assert_raises InvalidDep do
            Dep.parse(s, eapi, raised: true)
          end
          assert_raises InvalidDep do
            Dep.new(s, eapi)
          end
        end
      end
    end

    TESTDATA_TOML["dep"]["invalid"].each do |s|
      EAPIS.each_value do |eapi|
        refute(Dep.parse(s, eapi))
        assert_raises InvalidDep do
          Dep.parse(s, eapi, raised: true)
        end
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
      dep < "=cat/pkg-1"
    end

    TESTDATA_TOML["version"]["compares"].each do |s|
      s1, op, s2 = s.split
      d1 = Dep.new("=cat/pkg-#{s1}")
      d2 = Dep.new("=cat/pkg-#{s2}")
      assert(d1.public_send(op, d2))
    end
  end

  def test_intersects
    TESTDATA_TOML["dep"]["intersects"].each do |d|
      d["vals"].combination(2).each do |s1, s2|
        obj1 = Dep.new(s1)
        obj2 = Dep.new(s2)

        # elements intersect themselves
        assert(obj1.intersects(obj1))
        assert(obj2.intersects(obj2))

        # intersects depending on status
        if d["status"]
          assert(obj1.intersects(obj2))
          assert(obj2.intersects(obj1))
        else
          refute(obj1.intersects(obj2))
          refute(obj2.intersects(obj1))
        end
      end
    end

    # Cpv objects
    dep1 = Dep.new("=cat/pkg-1")
    dep2 = Dep.new(">cat/pkg-1")
    cpv = Cpv.new("cat/pkg-1")
    assert(dep1.intersects(cpv))
    assert(cpv.intersects(dep1))
    refute(dep2.intersects(cpv))
    refute(cpv.intersects(dep2))

    # packages
    temp = EbuildTemp.new
    pkg = temp.create_pkg("cat/pkg-1")
    assert(dep1.intersects(pkg))
    refute(dep2.intersects(pkg))

    # invalid type
    assert_raises TypeError do
      dep1.intersects("=cat/pkg-1")
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
