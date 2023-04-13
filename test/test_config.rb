# frozen_string_literal: true

require "test_helper"

class TestConfig < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Config
  include Pkgcraft::Error
  include Pkgcraft::Repos

  def test_repos
    config = Config.new
    assert_empty(config.repos)
    config.add_repo(EbuildTemp.new("r1"))
    refute_empty(config.repos)
  end

  def test_add_repo
    r1 = EbuildTemp.new("r1")
    r2 = EbuildTemp.new("r2")

    # string
    config = Config.new
    config.add_repo(r1.path.to_s, id: "r1")
    config.add_repo(r2.path.to_s, id: "r2")
    assert_equal([r1, r2], config.repos.entries)

    # path
    config = Config.new
    config.add_repo(r1.path, id: "r1")
    config.add_repo(r2.path, id: "r2")
    assert_equal([r1, r2], config.repos.entries)

    # repo
    config = Config.new
    config.add_repo(r1, id: "r1")
    config.add_repo(r2, id: "r2")
    assert_equal([r1, r2], config.repos.entries)

    # duplicate repo
    assert_raises ConfigError do
      config.add_repo(r1)
    end

    # nonexistent repo
    assert_raises PkgcraftError do
      config.add_repo("path/to/nonexistent/repo")
    end

    # invalid type
    assert_raises TypeError do
      config.add_repo([])
    end
  end
end

class TestRepos < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Config
  include Pkgcraft::Repos

  def test_methods
    config = Config.new
    assert_empty(config.repos)
    assert_equal(0, config.repos.length)
    repo = config.add_repo(EbuildTemp.new("r1"))
    assert_equal(1, config.repos.length)
    assert_equal(config.repos["r1"], repo)
    assert(config.repos.key?("r1"))
    assert_equal([repo], config.repos.entries)
    assert(config.repos.to_s)
  end
end
