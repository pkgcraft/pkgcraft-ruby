# frozen_string_literal: true

require "set"

require "test_helper"

class TestCpv < Minitest::Test
  include Pkgcraft::Dep
  include Pkgcraft::Error

  def test_new
    # revision
    cpv1 = Cpv.new("cat/pkg-1-r2")
    refute_nil(cpv1.category)
    assert_equal("cat", cpv1.category)
    refute_nil(cpv1.package)
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
    assert_includes(cpv1.inspect, "cat/pkg-1-r2")

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
    assert_includes(cpv2.inspect, "cat/pkg-2")
    assert(cpv1 < cpv2)

    # invalid
    ["=cat/pkg-1", "", nil].each do |s|
      assert_raises InvalidCpv do
        Cpv.new(s)
      end
    end
  end

  def test_cmp
    TESTDATA_TOML["version"]["compares"].each do |s|
      s1, op, s2 = s.split
      cpv1 = Cpv.new("cat/pkg-#{s1}")
      cpv2 = Cpv.new("cat/pkg-#{s2}")
      assert(cpv1.public_send(op, cpv2))
    end

    # invalid type
    cpv = Cpv.new("cat/pkg-1")
    assert_raises TypeError do
      assert(cpv < "cat/pkg-1")
    end
  end

  def test_intersects
    TESTDATA_TOML["version"]["compares"].each do |s|
      s1, op, s2 = s.split
      cpv1 = Cpv.new("cat/pkg-#{s1}")
      cpv2 = Cpv.new("cat/pkg-#{s2}")
      if op == "=="
        assert(cpv1.intersects(cpv2))
      else
        refute(cpv1.intersects(cpv2))
      end
    end

    # dep
    cpv = Cpv.new("cat/pkg-1")
    dep = Dep.new("=cat/pkg-1-r0")
    assert(cpv.intersects(dep))

    # invalid type
    assert_raises TypeError do
      cpv.intersects("cat/pkg-1")
    end
  end

  def test_hash
    TESTDATA_TOML["version"]["hashing"].each do |d|
      set = Set.new(d["versions"].map { |s| Cpv.new("cat/pkg-#{s}") }.compact)
      length = d["equal"] ? 1 : d["versions"].length
      assert_includes(set, set.entries.first)
      assert_equal(set.length, length)
    end
  end
end
