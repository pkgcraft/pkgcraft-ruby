# frozen_string_literal: true

require "test_helper"

class TestRepoBase < Minitest::Test
  include Pkgcraft::Dep
  include Pkgcraft::Repos
  include Pkgcraft::Restricts
  include Pkgcraft::Error

  def test_path
    repo = EbuildTemp.new
    path = repo.create_ebuild("cat/pkg-1")
    assert(path.to_s.start_with?(repo.path.to_s))
  end

  def test_categories
    # empty
    repo = EbuildTemp.new
    assert_empty(repo.categories)

    # single
    repo.create_ebuild("cat/pkg-1")
    assert_equal(["cat"], repo.categories)

    # multiple
    repo.create_ebuild("cat/pkg-2")
    repo.create_ebuild("a/b-1")
    assert_equal(["a", "cat"], repo.categories)
  end

  def test_packages
    repo = EbuildTemp.new
    assert_empty(repo.packages("cat"))

    # single
    repo.create_ebuild("cat/pkg-1")
    assert_equal(["pkg"], repo.packages("cat"))

    # multiple
    repo.create_ebuild("cat/pkg-2")
    repo.create_ebuild("cat/a-1")
    assert_equal(["a", "pkg"], repo.packages("cat"))
  end

  def test_versions
    repo = EbuildTemp.new
    assert_empty(repo.versions("cat", "pkg"))

    # single
    repo.create_ebuild("cat/pkg-1")
    assert_equal([Version.new("1")], repo.versions("cat", "pkg"))

    # multiple
    repo.create_ebuild("cat/pkg-2")
    assert_equal([Version.new("1"), Version.new("2")], repo.versions("cat", "pkg"))
  end

  def test_length
    repo = EbuildTemp.new
    assert_equal(0, repo.length)

    # single
    repo.create_ebuild("cat/pkg-1")
    assert_equal(1, repo.length)

    # multiple
    repo.create_ebuild("cat/pkg-2")
    assert_equal(2, repo.length)
  end

  def test_empty
    repo = EbuildTemp.new
    assert_empty(repo)
    repo.create_ebuild("cat/pkg-1")
    refute_empty(repo)
  end

  def test_contains
    repo = EbuildTemp.new
    pkg = repo.create_pkg("cat/pkg-1")

    # path
    assert(repo.contains?("cat/pkg"))

    # nonexistent path
    refute(repo.contains?("nonexistent/path"))

    # Cpv
    assert(repo.contains?(Cpv.new("cat/pkg-1")))

    # Pkg
    assert(repo.contains?(pkg))
  end

  def test_cmp
    r1 = EbuildTemp.new(id: "1")
    r2 = EbuildTemp.new(id: "2")
    r3 = EbuildTemp.new(id: "3", priority: 1)
    assert_operator(r1, :<, r2)
    assert_operator(r3, :<, r1)

    # invalid type
    assert_raises TypeError do
      r1 < "repo"
    end
  end

  def test_hash
    r1 = EbuildTemp.new(id: "1")
    r2 = EbuildTemp.new(id: "2")

    # equal
    repos = Set.new([r1, r1])
    assert_equal(1, repos.length)

    # unequal
    repos = Set.new([r1, r2])
    assert_equal(2, repos.length)
  end

  def test_string
    repo = EbuildTemp.new(id: "repo")
    assert_equal("repo", repo.to_s)
    assert_includes(repo.inspect, "repo")
  end

  def test_iter_cpv
    # empty
    repo = EbuildTemp.new
    assert_empty(repo)

    # single
    pkg1 = repo.create_pkg("cat/pkg-1")
    assert_equal([pkg1.cpv], repo.iter_cpv.entries)

    # multiple
    pkg2 = repo.create_pkg("a/b-1")
    assert_equal([pkg2.cpv, pkg1.cpv], repo.iter_cpv.entries)
  end

  def test_iter
    # empty
    repo = EbuildTemp.new
    assert_empty(repo)

    # single
    pkg1 = repo.create_pkg("cat/pkg-1")
    assert_equal([pkg1], repo.entries)

    # multiple
    pkg2 = repo.create_pkg("a/b-1")
    assert_equal([pkg2, pkg1], repo.entries)
  end

  def test_iter_restrict
    repo = EbuildTemp.new
    pkg1 = repo.create_pkg("cat/pkg-1")
    pkg2 = repo.create_pkg("cat/pkg-2")
    assert_equal([pkg1], repo.iter("cat/pkg-1").entries)
    assert_equal([pkg1], repo.iter(Cpv.new("cat/pkg-1")).entries)
    assert_equal([pkg1, pkg2], repo.iter(Dep.new(">=cat/pkg-1")).entries)
    assert_equal([pkg1], repo.iter(pkg1).entries)
    assert_equal([pkg1, pkg2], repo.iter("cat/*").entries)
    assert_equal([pkg1], repo.iter(Restrict.new("cat/pkg-1")).entries)
  end
end
