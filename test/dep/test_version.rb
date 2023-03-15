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
    assert_equal(v1.to_s, "1")
    v1 = Version.new("1-r2")
    assert_nil(v1.op)
    assert_equal(v1.revision, "2")
    assert_equal(v1.to_s, "1-r2")

    v2 = Version.new("2")
    assert(v1 < v2)

    # invalid
    assert_raises InvalidVersion do
      Version.new("=1")
    end
  end

  # Convert string to op-ed version falling back to non-op version.
  def parse(str)
    VersionWithOp.new(str)
  rescue InvalidVersion
    Version.new(str)
  end

  def test_intersects
    TOML["version"]["intersects"].each do |d|
      d["vals"].combination(2).each do |s1, s2|
        v1 = parse(s1)
        v2 = parse(s2)

        # elements intersect themselves
        assert(v1.intersects(v1))
        assert(v2.intersects(v2))

        # intersects depending on status
        if d["status"]
          assert(v1.intersects(v2))
        else
          assert(!v1.intersects(v2))
        end
      end
    end
  end

  # TODO: use shared toml test data
  def test_hash
    # equal
    v1 = Version.new("1")
    v2 = Version.new("1-r0")
    versions = Set.new([v1, v2])
    assert_equal(versions.length, 1)

    # unequal
    v1 = Version.new("1")
    v2 = Version.new("1.0")
    versions = Set.new([v1, v2])
    assert_equal(versions.length, 2)
  end
end

class TestVersionWithOp < Minitest::Test
  include Pkgcraft::Dep
  include Pkgcraft::Error

  def test_new
    # valid
    v1 = VersionWithOp.new(">1")
    assert_equal(v1.op, :Greater)
    assert_nil(v1.revision)
    assert_equal(v1.to_s, ">1")

    v2 = VersionWithOp.new("=2")
    assert_equal(v2.op, :Equal)
    assert(v1 < v2)

    # invalid
    assert_raises InvalidVersion do
      VersionWithOp.new("1")
    end
  end
end
