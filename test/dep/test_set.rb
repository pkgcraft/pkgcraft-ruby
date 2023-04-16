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
end
