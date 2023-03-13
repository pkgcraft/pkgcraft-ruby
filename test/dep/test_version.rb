# frozen_string_literal: true

require "set"

require "test_helper"

class TestVersion < Minitest::Test
  def test_new
    # valid
    v1 = Pkgcraft::Dep::Version.new("1")
    assert_nil(v1.revision)
    assert_equal(v1.to_s, "1")
    v1 = Pkgcraft::Dep::Version.new("1-r2")
    assert_equal(v1.revision, "2")
    assert_equal(v1.to_s, "1-r2")

    v2 = Pkgcraft::Dep::Version.new("2")
    assert(v1 < v2)

    # invalid
    assert_raises RuntimeError do
      Pkgcraft::Dep::Version.new("=1")
    end
  end

  # TODO: use shared toml test data
  def test_hash
    # equal
    v1 = Pkgcraft::Dep::Version.new("1")
    v2 = Pkgcraft::Dep::Version.new("1-r0")
    versions = Set.new([v1, v2])
    assert_equal(versions.length, 1)

    # unequal
    v1 = Pkgcraft::Dep::Version.new("1")
    v2 = Pkgcraft::Dep::Version.new("1.0")
    versions = Set.new([v1, v2])
    assert_equal(versions.length, 2)
  end
end

class TestVersionWithOp < Minitest::Test
  def test_new
    # valid
    v1 = Pkgcraft::Dep::VersionWithOp.new(">1")
    assert_nil(v1.revision)
    assert_equal(v1.to_s, ">1")

    v2 = Pkgcraft::Dep::VersionWithOp.new("=2")
    assert(v1 < v2)

    # invalid
    assert_raises RuntimeError do
      Pkgcraft::Dep::VersionWithOp.new("1")
    end
  end
end
