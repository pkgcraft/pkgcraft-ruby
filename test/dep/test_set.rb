# frozen_string_literal: true

require "test_helper"

class TestDependencies < Minitest::Test
  include Pkgcraft::Dep
  include Pkgcraft::Error

  def test_string
    # no args
    dep = Dependencies.new
    assert_empty(dep.to_s)
    assert_includes(dep.inspect, dep.to_s)

    ["", "a/b"].each do |s|
      dep = Dependencies.new(s)
      assert_equal(s, dep.to_s)
    end
  end

  def test_invalid
    assert_raises PkgcraftError do
      Dependencies.new("u? ( cat/pkg)")
    end
  end

  def test_eq_and_hash
    [
      ["a/dep", "a/dep"],
      ["a/b c/d", "c/d a/b"]
    ].each do |s1, s2|
      dep1 = Dependencies.new(s1)
      dep2 = Dependencies.new(s2)
      assert_equal(dep1, dep2)
      set = Set[dep1, dep2]
      assert_equal(1, set.length)
      assert_includes(set, dep2)

      # invalid type
      assert_raises TypeError do
        dep1 == ""
      end
    end
  end

  def test_iter
    # empty
    dep = Dependencies.new
    assert_empty(dep.entries)

    # single
    dep = Dependencies.new("cat/pkg")
    assert_equal(["cat/pkg"], dep.map(&:to_s))

    # multiple
    dep = Dependencies.new("a/b u? ( c/d )")
    assert_equal(["a/b", "u? ( c/d )"], dep.map(&:to_s))
  end

  def test_iter_flatten_dep
    # empty
    dep = Dependencies.new
    assert_empty(dep.iter_flatten.entries)

    # single
    dep = Dependencies.new("cat/pkg")
    assert_equal(["cat/pkg"], dep.iter_flatten.map(&:to_s))

    # multiple
    dep = Dependencies.new("a/b u? ( c/d )")
    assert_equal(["a/b", "c/d"], dep.iter_flatten.map(&:to_s))
  end

  def test_iter_flatten_string
    # empty
    license = License.new
    assert_empty(license.iter_flatten.entries)

    # single
    license = License.new("BSD")
    assert_equal(["BSD"], license.iter_flatten.map(&:to_s))

    # multiple
    dep = License.new("BSD u? ( GPL-3 )")
    assert_equal(["BSD", "GPL-3"], dep.iter_flatten.map(&:to_s))
  end

  def test_iter_recursive
    # empty
    dep = Dependencies.new
    assert_empty(dep.iter_recursive.entries)

    # single
    dep = Dependencies.new("cat/pkg")
    assert_equal(["cat/pkg"], dep.iter_flatten.map(&:to_s))

    # multiple
    dep = Dependencies.new("a/b u? ( c/d )")
    assert_equal(["a/b", "u? ( c/d )", "c/d"], dep.iter_recursive.map(&:to_s))
  end
end
