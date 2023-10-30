# frozen_string_literal: true

require "set"

require "test_helper"

class TestVersion < Minitest::Test
  include Pkgcraft::Dep
  include Pkgcraft::Error

  def test_new
    # valid
    v1 = Version.new("1")
    assert_nil(v1.revision)
    assert_equal("1", v1.to_s)
    assert_includes(v1.inspect, "1")
    v1 = Version.new("1-r2")
    assert_nil(v1.op)
    assert_equal(v1.revision, Revision.new("2"))
    assert_equal("1-r2", v1.to_s)
    assert_includes(v1.inspect, "1-r2")

    v2 = Version.new("2")
    assert_operator(v1, :<, v2)

    # valid op-ed
    v1 = Version.new(">1")
    assert_equal(:Greater, v1.op)
    assert_nil(v1.revision)
    assert_equal(">1", v1.to_s)
    assert_includes(v1.inspect, ">1")

    v2 = Version.new("=2")
    assert_equal(:Equal, v2.op)
    assert_operator(v1, :<, v2)

    # invalid
    ["-1", "", nil].each do |s|
      assert_raises InvalidVersion do
        Version.new(s)
      end
    end
  end

  def test_intersects
    TESTDATA_TOML["version"]["intersects"].each do |d|
      d["vals"].combination(2).each do |s1, s2|
        obj1 = Version.new(s1)
        obj2 = Version.new(s2)

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
  end

  def test_cmp
    TESTDATA_TOML["version"]["compares"].each do |s|
      s1, op, s2 = s.split
      v1 = Version.new(s1)
      v2 = Version.new(s2)
      assert(v1.public_send(op, v2))
    end

    # invalid type
    ver = Version.new("1")
    assert_raises TypeError do
      ver < "1"
    end
  end

  def test_sort
    TESTDATA_TOML["version"]["sorting"].each do |d|
      expected = d["sorted"].map { |s| Version.new(s) }.compact
      reversed = expected.reverse
      ordered = reversed.sort
      # equal objects aren't sorted so reversing should restore original order
      ordered = ordered.reverse if d["equal"]
      assert_equal(ordered, expected)
    end
  end

  def test_hash
    TESTDATA_TOML["version"]["hashing"].each do |d|
      versions = Set.new(d["versions"].map { |s| Version.new(s) }.compact)
      length = d["equal"] ? 1 : d["versions"].length
      assert_equal(versions.length, length)
    end
  end
end
