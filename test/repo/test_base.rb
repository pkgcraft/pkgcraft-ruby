# frozen_string_literal: true

require "test_helper"

class TestRepoBase < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Repo
  include Pkgcraft::Error

  def test_categories
    repo = EbuildTemp.new("test")
    assert_empty(repo.categories)
  end

  def test_packages
    repo = EbuildTemp.new("test")
    assert_empty(repo.packages("cat"))
  end

  def test_versions
    repo = EbuildTemp.new("test")
    assert_empty(repo.versions("cat", "pkg"))
  end

  def test_length
    repo = EbuildTemp.new("test")
    assert_equal(0, repo.length)
  end
end
