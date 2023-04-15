# frozen_string_literal: true

require "test_helper"

class TestPkgEbuild < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Dep
  include Pkgcraft::Eapis
  include Pkgcraft::Repos

  def test_cpv
    repo = EbuildTemp.new
    pkg = repo.create_pkg("cat/pkg-1-r2")
    assert_equal(Cpv.new("cat/pkg-1-r2"), pkg.cpv)
    assert_equal("pkg-1", pkg.p)
    assert_equal("pkg-1-r2", pkg.pf)
    assert_equal("r2", pkg.pr)
    assert_equal("1", pkg.pv)
    assert_equal("1-r2", pkg.pvr)
    assert_equal("cat/pkg", pkg.cpn)
  end

  def test_eapi
    # default
    repo = EbuildTemp.new
    pkg = repo.create_pkg("cat/pkg-1")
    assert_equal(EAPI_LATEST_OFFICIAL, pkg.eapi)

    # explicit
    pkg = repo.create_pkg("cat/pkg-1", "EAPI=5")
    assert_equal(EAPI5, pkg.eapi)
  end

  def test_repo
    repo = EbuildTemp.new
    pkg = repo.create_pkg("cat/pkg-1")
    assert_equal(repo, pkg.repo)
  end

  def test_version
    repo = EbuildTemp.new
    pkg = repo.create_pkg("cat/pkg-1")
    assert_equal(Version.new("1"), pkg.version)
  end

  def test_cmp
    repo = EbuildTemp.new
    pkg1 = repo.create_pkg("cat/pkg-1")
    pkg2 = repo.create_pkg("cat/pkg-2")
    pkg3 = repo.create_pkg("cat/pkg-1-r0")
    assert(pkg1 < pkg2)
    assert(pkg1 <= pkg2)
    assert_equal(pkg1, pkg3)
    refute_equal(pkg1, pkg2)
    assert(pkg2 >= pkg1)
    assert(pkg2 > pkg1)

    # invalid type
    assert_raises TypeError do
      assert(pkg1 < "cat/pkg-1")
    end
  end
end
