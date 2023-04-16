# frozen_string_literal: true

require "test_helper"

class TestPkgEbuild < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Dep
  include Pkgcraft::Eapis
  include Pkgcraft::Error
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

  def test_path
    repo = EbuildTemp.new
    path = repo.create_ebuild("cat/pkg-1")
    pkg = repo.iter("cat/pkg-1").first
    assert_equal(path, pkg.path)
  end

  def test_ebuild
    repo = EbuildTemp.new
    pkg = repo.create_pkg("cat/pkg-1")
    data = File.read(pkg.path)
    assert_equal(data, pkg.ebuild)

    # missing file causes error
    pkg.path.delete
    assert_raises PkgcraftError do
      pkg.ebuild
    end
  end

  def test_description
    repo = EbuildTemp.new
    pkg = repo.create_pkg("cat/pkg-1", "DESCRIPTION=description")
    assert_equal("description", pkg.description)
  end

  def test_slot_and_subslot
    repo = EbuildTemp.new
    pkg = repo.create_pkg("cat/pkg-1", "SLOT=1")
    assert_equal("1", pkg.slot)
    assert_equal("1", pkg.subslot)
    pkg = repo.create_pkg("cat/pkg-1", "SLOT=1/2")
    assert_equal("1", pkg.slot)
    assert_equal("2", pkg.subslot)
    pkg = repo.create_pkg("cat/pkg-1", "SLOT=slot")
    assert_equal("slot", pkg.slot)
    assert_equal("slot", pkg.subslot)
  end

  def test_dependencies
    repo = EbuildTemp.new
    pkg = repo.create_pkg("cat/pkg-1")

    # invalid keys
    assert_raises PkgcraftError do
      pkg.dependencies("invalid")
    end

    # empty
    deps = pkg.dependencies
    assert_empty(deps.to_s)

    # single
    pkg = repo.create_pkg("cat/pkg-1", "DEPEND=cat/pkg")
    deps = pkg.dependencies
    assert_equal("cat/pkg", deps.to_s)

    # multiple
    pkg = repo.create_pkg("cat/pkg-1", "DEPEND=u? ( cat/pkg )", "BDEPEND=a/b")
    deps = pkg.dependencies
    assert_equal("a/b u? ( cat/pkg )", deps.to_s)

    # filter by type
    deps = pkg.dependencies("bdepend")
    assert_equal("a/b", deps.to_s)
  end

  def test_dep_attrs
    repo = EbuildTemp.new
    EAPI_LATEST.dep_keys.map(&:downcase).each do |attr|
      # undefined
      pkg = repo.create_pkg("cat/pkg-1")
      assert_nil(pkg.send(attr))

      # explicitly defined empty
      pkg = repo.create_pkg("cat/pkg-1", "#{attr.upcase}=")
      assert_nil(pkg.send(attr))

      # explicitly defined empty
      pkg = repo.create_pkg("cat/pkg-1", "#{attr.upcase}=cat/pkg")
      val = pkg.send(attr)
      assert_equal("cat/pkg", val.to_s)
    end
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
