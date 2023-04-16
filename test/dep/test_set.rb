# frozen_string_literal: true

require "test_helper"

class TestDependencies < Minitest::Test
  include Pkgcraft::Dep
  include Pkgcraft::Error

  def test_string
    # no args
    dep = Dependencies.new
    assert_equal("", dep.to_s)

    ["", "a/b"].each do |s|
      dep = Dependencies.new(s)
      assert_equal(s, dep.to_s)
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
      assert_equal(1, Set[dep1, dep2].length)
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

  def test_iter_flatten
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
end
