# frozen_string_literal: true

require "test_helper"

class TestConfig < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Configs
  include Pkgcraft::Error
  include Pkgcraft::Repos

  def test_repos
    config = Config.new
    assert_empty(config.repos)
    config.add_repo(EbuildTemp.new(id: "r1"))
    refute_empty(config.repos)
  end

  def test_load_portage_conf
    config = Config.new

    # nonexistent
    assert_raises PkgcraftError do
      config.load_portage_conf("nonexistent/path")
    end

    Dir.mktmpdir do |dir|
      conf_path = dir

      # empty
      f = File.open("#{conf_path}/repos.conf", "w")
      config.load_portage_conf(conf_path)
      assert_empty(config.repos)

      r1 = EbuildTemp.new(id: "r1")

      # bad ini format
      data = <<~CONFIG
        [test
        location = #{r1.path}
      CONFIG
      f.write(data)
      f.rewind
      assert_raises PkgcraftError do
        config.load_portage_conf(conf_path)
      end

      # single repo
      data = <<~CONFIG
        [test]
        location = #{r1.path}
      CONFIG
      f.write(data)
      f.rewind
      config.load_portage_conf(conf_path)
      assert(config.repos.key?("test"))

      # reloading succeeds
      config.load_portage_conf(conf_path)

      # reloading using a different id causes error
      data = <<~CONFIG
        [existing]
        location = #{r1.path}
      CONFIG
      f.write(data)
      f.rewind
      assert_raises PkgcraftError do
        config.load_portage_conf(conf_path)
      end

      # dir path
      File.unlink("#{conf_path}/repos.conf")
      Dir.mkdir("#{conf_path}/repos.conf")
      d1 = <<~CONFIG
        [r1]
        location = #{r1.path}
      CONFIG
      File.write("#{conf_path}/repos.conf/1.conf", d1)

      r2 = EbuildTemp.new(id: "r2")
      d2 = <<~CONFIG
        [r2]
        location = #{r2.path}
      CONFIG
      File.write("#{conf_path}/repos.conf/2.conf", d2)

      config = Config.new
      config.load_portage_conf(conf_path)
      assert_equal([r1, r2], config.repos.entries)
    end
  end

  def test_add_repo
    r1 = EbuildTemp.new(id: "r1")
    r2 = EbuildTemp.new(id: "r2")

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

    # reloading succeeds
    assert_equal(r1, config.add_repo(r1))

    # reloading using a different id causes error
    assert_raises ConfigError do
      config.add_repo(r1.path, id: "existing")
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
  include Pkgcraft::Configs
  include Pkgcraft::Repos

  def test_methods
    config = Config.new
    assert_empty(config.repos)
    assert_equal(0, config.repos.length)
    repo = config.add_repo(EbuildTemp.new(id: "r1"))
    assert_equal(1, config.repos.length)
    assert_equal(config.repos["r1"], repo)
    assert(config.repos.key?("r1"))
    assert_equal([repo], config.repos.entries)
    assert(config.repos.to_s)
  end

  def test_repo_sets
    # empty
    config = Config.new
    assert_equal(RepoSet.new, config.repos.all)
    assert_empty(config.repos.all)
    assert_equal(RepoSet.new, config.repos.ebuild)
    assert_empty(config.repos.ebuild)

    # multiple
    r1 = EbuildTemp.new(id: "r1")
    r2 = Fake.new(id: "r2")
    config.add_repo(r1)
    config.add_repo(r2)
    assert_equal(RepoSet.new(r1, r2), config.repos.all)
    assert_equal(RepoSet.new(r1), config.repos.ebuild)
  end
end
