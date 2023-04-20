# frozen_string_literal: true

require "test_helper"

class TestDepSpec < Minitest::Test
  include Pkgcraft::Dep

  def test_iter_flatten
    # single
    dep_spec = Dependencies.new("cat/pkg").entries.first
    assert_equal(["cat/pkg"], dep_spec.iter_flatten.map(&:to_s))
    dep_spec = Dependencies.new("u? ( a/b )").entries.first
    assert_equal(["a/b"], dep_spec.iter_flatten.map(&:to_s))
    assert_includes(dep_spec.inspect, dep_spec.to_s)

    # multiple nested
    dep_spec = Dependencies.new("u? ( || ( a/b c/d ) e/f )").entries.first
    assert_equal(["a/b", "c/d", "e/f"], dep_spec.iter_flatten.map(&:to_s))
  end

  def test_iter_recursive
    # single
    dep_spec = Dependencies.new("cat/pkg").entries.first
    assert_equal(["cat/pkg"], dep_spec.iter_recursive.map(&:to_s))
    dep_spec = Dependencies.new("u? ( a/b )").entries.first
    assert_equal(["u? ( a/b )", "a/b"], dep_spec.iter_recursive.map(&:to_s))

    # multiple nested
    dep_spec = Dependencies.new("u? ( || ( a/b c/d ) e/f )").entries.first
    assert_equal(
      ["u? ( || ( a/b c/d ) e/f )", "|| ( a/b c/d )", "a/b", "c/d", "e/f"],
      dep_spec.iter_recursive.map(&:to_s)
    )
  end
end
