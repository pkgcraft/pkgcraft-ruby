# frozen_string_literal: true

require "test_helper"

class TestRepoBase < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Repos
  include Pkgcraft::Error

  def test_categories
    # empty
    repo = EbuildTemp.new("test")
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
    repo = EbuildTemp.new("test")
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
    repo = EbuildTemp.new("test")
    assert_empty(repo.versions("cat", "pkg"))

    # single
    repo.create_ebuild("cat/pkg-1")
    assert_equal(["1"], repo.versions("cat", "pkg"))

    # multiple
    repo.create_ebuild("cat/pkg-2")
    assert_equal(["1", "2"], repo.versions("cat", "pkg"))
  end

  def test_length
    repo = EbuildTemp.new("test")
    assert_equal(0, repo.length)

    # single
    repo.create_ebuild("cat/pkg-1")
    assert_equal(1, repo.length)

    # multiple
    repo.create_ebuild("cat/pkg-2")
    assert_equal(2, repo.length)
  end
end
