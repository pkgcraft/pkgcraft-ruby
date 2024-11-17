# frozen_string_literal: true

require "test_helper"

class TestRepoSet < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Dep
  include Pkgcraft::Repos
  include Pkgcraft::Restricts

  def test_repos
    # empty
    set = RepoSet.new
    assert_empty(set.repos)

    # single
    temp = EbuildTemp.new(id: "r1")
    r1 = temp.repo
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

  def test_contains
    # empty
    set = RepoSet.new
    refute(set.contains?("cat/pkg-1"))

    temp = EbuildTemp.new(id: "r1")
    temp.create_pkg("cat/pkg-1")
    r1 = temp.repo
    r2 = Fake.new(["cat/pkg-2"], id: "r2")
    set = RepoSet.new(r1, r2)
    assert(set.contains?(r1))
    assert(set.contains?(r2))
    assert(set.contains?(Cpv.new("cat/pkg-1")))
    assert(set.contains?(Dep.new(">=cat/pkg-2")))
    refute(set.contains?(Dep.new("=cat/pkg-3")))
    assert(set.contains?(Restrict.new("*/pkg")))
    refute(set.contains?(Restrict.new("*::r3")))
    assert(set.contains?("cat/pkg"))
  end

  def test_hash
    s1 = RepoSet.new
    s2 = RepoSet.new
    s3 = RepoSet.new(Fake.new)
    assert_equal(1, Set[s1, s1].length)
    assert_equal(1, Set[s1, s2].length)
    assert_equal(2, Set[s1, s3].length)
  end

  def test_cmp
    r1 = Fake.new(id: "r1")
    r2 = Fake.new(id: "r2")
    s0 = RepoSet.new
    s1 = RepoSet.new(r1)
    s2 = RepoSet.new(r2)
    assert_operator(s1, :<, s2)
    assert_operator(s1, :>, s0)

    # invalid type
    assert_raises TypeError do
      s1 < r1
    end
  end

  def test_iter
    set = RepoSet.new
    assert_empty(set.entries)

    r1 = Fake.new(["cat/pkg-1"], id: "r1")
    temp = EbuildTemp.new(id: "r2")
    temp.create_pkg("cat/pkg-1")
    r2 = temp.repo

    # single
    set = RepoSet.new(r1)
    assert_equal(["cat/pkg-1::r1"], set.entries.map(&:to_s))
    assert_empty(set.iter("*::r2").entries.map(&:to_s))

    # multiple
    set = RepoSet.new(r2, r1)
    assert_equal(["cat/pkg-1::r1", "cat/pkg-1::r2"], set.entries.map(&:to_s))
    assert_equal(["cat/pkg-1::r2"], set.iter("*::r2").entries.map(&:to_s))
    assert_equal(["cat/pkg-1::r2"], set.iter(Restrict.new("*::r2")).entries.map(&:to_s))
  end
end
