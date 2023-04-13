# frozen_string_literal: true

require "test_helper"

class TestRepoSet < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Repos

  def test_new
    # empty
    set = RepoSet.new
    assert_empty(set)

    # single
    r1 = EbuildTemp.new(id: "r1")
    set = RepoSet.new(r1)
    assert_equal(Set[r1], set.repos)

    # multiple
    r2 = Fake.new(id: "r2")
    set = RepoSet.new(r1, r2)
    assert_equal(Set[r1, r2], set.repos)
  end

  def test_empty_and_length
    set = RepoSet.new
    assert_empty(set)
    assert_equal(0, set.length)
    set = RepoSet.new(Fake.new(["cat/pkg-1"]))
    refute_empty(set)
    assert_equal(1, set.length)
  end

  def test_hash
    s1 = RepoSet.new
    s2 = RepoSet.new
    assert_equal(1, Set[s1, s1].length)
    assert_equal(2, Set[s1, s2].length)
  end
end
