# frozen_string_literal: true

require "test_helper"

class TestRepoBase < Minitest::Test
  include Pkgcraft::Dep
  include Pkgcraft::Repos
  include Pkgcraft::Restricts
  include Pkgcraft::Error

  def test_path
    temp = EbuildTemp.new
    pkg = temp.create_pkg("cat/pkg-1")
    assert(pkg.path.to_s.start_with?(temp.repo.path.to_s))
  end

  def test_categories
    # empty
    temp = EbuildTemp.new
    assert_empty(temp.repo.categories)

    # single
    temp.create_pkg("cat/pkg-1")
    assert_equal(["cat"], temp.repo.categories)

    # multiple
    temp.create_pkg("cat/pkg-2")
    temp.create_pkg("a/b-1")
    assert_equal(["a", "cat"], temp.repo.categories)
  end

  def test_packages
    temp = EbuildTemp.new
    assert_empty(temp.repo.packages("cat"))

    # single
    temp.create_pkg("cat/pkg-1")
    assert_equal(["pkg"], temp.repo.packages("cat"))

    # multiple
    temp.create_pkg("cat/pkg-2")
    temp.create_pkg("cat/a-1")
    assert_equal(["a", "pkg"], temp.repo.packages("cat"))
  end

  def test_versions
    temp = EbuildTemp.new
    assert_empty(temp.repo.versions("cat", "pkg"))

    # single
    temp.create_pkg("cat/pkg-1")
    assert_equal([Version.new("1")], temp.repo.versions("cat", "pkg"))

    # multiple
    temp.create_pkg("cat/pkg-2")
    assert_equal([Version.new("1"), Version.new("2")], temp.repo.versions("cat", "pkg"))
  end

  def test_length
    temp = EbuildTemp.new
    assert_equal(0, temp.repo.length)

    # single
    temp.create_pkg("cat/pkg-1")
    assert_equal(1, temp.repo.length)

    # multiple
    temp.create_pkg("cat/pkg-2")
    assert_equal(2, temp.repo.length)
  end

  def test_empty
    temp = EbuildTemp.new
    assert_empty(temp.repo)
    temp.create_pkg("cat/pkg-1")
    refute_empty(temp.repo)
  end

  def test_contains
    temp = EbuildTemp.new
    pkg = temp.create_pkg("cat/pkg-1")

    # path
    assert(temp.repo.contains?("cat/pkg"))

    # nonexistent path
    refute(temp.repo.contains?("nonexistent/path"))

    # Cpv
    assert(temp.repo.contains?(Cpv.new("cat/pkg-1")))

    # Pkg
    assert(temp.repo.contains?(pkg))
  end

  def test_cmp
    temp1 = EbuildTemp.new(id: "1")
    r1 = temp1.repo
    temp2 = EbuildTemp.new(id: "2")
    r2 = temp2.repo
    temp3 = EbuildTemp.new(id: "3", priority: 1)
    r3 = temp3.repo
    assert_operator(r1, :<, r2)
    assert_operator(r3, :<, r1)

    # invalid type
    assert_raises TypeError do
      r1 < "repo"
    end
  end

  def test_hash
    temp1 = EbuildTemp.new(id: "1")
    r1 = temp1.repo
    temp2 = EbuildTemp.new(id: "2")
    r2 = temp2.repo

    # equal
    repos = Set.new([r1, r1])
    assert_equal(1, repos.length)

    # unequal
    repos = Set.new([r1, r2])
    assert_equal(2, repos.length)
  end

  def test_string
    temp = EbuildTemp.new(id: "repo")
    assert_equal("repo", temp.repo.to_s)
    assert_includes(temp.repo.inspect, "repo")
  end

  def test_iter_cpv
    # empty
    temp = EbuildTemp.new
    assert_empty(temp.repo)

    # single
    pkg1 = temp.create_pkg("cat/pkg-1")
    assert_equal([pkg1.cpv], temp.repo.iter_cpv.entries)

    # multiple
    pkg2 = temp.create_pkg("a/b-1")
    assert_equal([pkg2.cpv, pkg1.cpv], temp.repo.iter_cpv.entries)
  end

  def test_iter
    # empty
    temp = EbuildTemp.new
    assert_empty(temp.repo)

    # single
    pkg1 = temp.create_pkg("cat/pkg-1")
    assert_equal([pkg1], temp.repo.entries)

    # multiple
    pkg2 = temp.create_pkg("a/b-1")
    assert_equal([pkg2, pkg1], temp.repo.entries)
  end

  def test_iter_restrict
    temp = EbuildTemp.new
    pkg1 = temp.create_pkg("cat/pkg-1")
    pkg2 = temp.create_pkg("cat/pkg-2")
    repo = temp.repo
    assert_equal([pkg1], repo.iter("cat/pkg-1").entries)
    assert_equal([pkg1], repo.iter(Cpv.new("cat/pkg-1")).entries)
    assert_equal([pkg1, pkg2], repo.iter(Dep.new(">=cat/pkg-1")).entries)
    assert_equal([pkg1], repo.iter(pkg1).entries)
    assert_equal([pkg1, pkg2], repo.iter("cat/*").entries)
    assert_equal([pkg1], repo.iter(Restrict.new("cat/pkg-1")).entries)
  end
end
