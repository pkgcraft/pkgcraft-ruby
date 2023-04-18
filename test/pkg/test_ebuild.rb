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

      # empty
      pkg = repo.create_pkg("cat/pkg-1", "#{attr.upcase}=")
      assert_nil(pkg.send(attr))

      # defined
      pkg = repo.create_pkg("cat/pkg-1", "#{attr.upcase}=cat/pkg")
      refute_nil(pkg.send(attr))
      assert_equal("cat/pkg", pkg.send(attr).to_s)
    end
  end

  def test_license
    repo = EbuildTemp.new
    # undefined
    pkg = repo.create_pkg("cat/pkg-1")
    assert_nil(pkg.license)

    # empty
    pkg = repo.create_pkg("cat/pkg-1", "LICENSE=")
    assert_nil(pkg.license)

    # defined
    pkg = repo.create_pkg("cat/pkg-1", "LICENSE=BSD")
    refute_nil(pkg.license)
    assert_equal("BSD", pkg.license.to_s)
  end

  def test_properties
    repo = EbuildTemp.new
    # undefined
    pkg = repo.create_pkg("cat/pkg-1")
    assert_nil(pkg.properties)

    # empty
    pkg = repo.create_pkg("cat/pkg-1", "PROPERTIES=")
    assert_nil(pkg.properties)

    # defined
    pkg = repo.create_pkg("cat/pkg-1", "PROPERTIES=live")
    refute_nil(pkg.properties)
    assert_equal("live", pkg.properties.to_s)
  end

  def test_required_use
    repo = EbuildTemp.new
    # undefined
    pkg = repo.create_pkg("cat/pkg-1")
    assert_nil(pkg.required_use)

    # empty
    pkg = repo.create_pkg("cat/pkg-1", "REQUIRED_USE=")
    assert_nil(pkg.required_use)

    # defined
    pkg = repo.create_pkg("cat/pkg-1", "REQUIRED_USE=u1? ( u2 )")
    refute_nil(pkg.required_use)
    assert_equal("u1? ( u2 )", pkg.required_use.to_s)
  end

  def test_restrict
    repo = EbuildTemp.new
    # undefined
    pkg = repo.create_pkg("cat/pkg-1")
    assert_nil(pkg.restrict)

    # empty
    pkg = repo.create_pkg("cat/pkg-1", "RESTRICT=")
    assert_nil(pkg.restrict)

    # defined
    pkg = repo.create_pkg("cat/pkg-1", "RESTRICT=test")
    refute_nil(pkg.restrict)
    assert_equal("test", pkg.restrict.to_s)
  end

  def test_src_uri
    repo = EbuildTemp.new
    # undefined
    pkg = repo.create_pkg("cat/pkg-1")
    assert_nil(pkg.src_uri)

    # empty
    pkg = repo.create_pkg("cat/pkg-1", "SRC_URI=")
    assert_nil(pkg.src_uri)

    # defined
    pkg = repo.create_pkg("cat/pkg-1", "SRC_URI=https://a.com/file.tar.gz")
    refute_nil(pkg.src_uri)
    assert_equal("https://a.com/file.tar.gz", pkg.src_uri.to_s)
  end

  def test_defined_phases
    repo = EbuildTemp.new
    # none
    pkg = repo.create_pkg("cat/pkg-1")
    assert_empty(pkg.defined_phases)

    # single
    data = "src_configure() { :; }"
    pkg = repo.create_pkg("cat/pkg-1", data: data)
    assert_equal(Set["configure"], pkg.defined_phases)

    # multiple
    data = <<~PHASES
      src_prepare() { :; }
      src_configure() { :; }
      src_compile() { :; }
    PHASES
    pkg = repo.create_pkg("cat/pkg-1", data: data)
    refute_empty(pkg.defined_phases)
    assert_equal(Set["prepare", "configure", "compile"], pkg.defined_phases)
  end

  def test_homepage
    repo = EbuildTemp.new
    # none
    pkg = repo.create_pkg("cat/pkg-1")
    assert_empty(pkg.homepage)

    # single
    pkg = repo.create_pkg("cat/pkg-1", "HOMEPAGE=https://a.com")
    assert_equal(Set["https://a.com"], pkg.homepage)

    # multiple
    pkg = repo.create_pkg("cat/pkg-1", "HOMEPAGE=https://a.com https://b.com")
    refute_empty(pkg.homepage)
    assert_equal(Set["https://a.com", "https://b.com"], pkg.homepage)
  end

  def test_keywords
    repo = EbuildTemp.new
    # none
    pkg = repo.create_pkg("cat/pkg-1")
    assert_empty(pkg.keywords)

    # single
    pkg = repo.create_pkg("cat/pkg-1", "KEYWORDS=amd64")
    assert_equal(Set["amd64"], pkg.keywords)

    # multiple
    pkg = repo.create_pkg("cat/pkg-1", "KEYWORDS=amd64 ~arm64")
    refute_empty(pkg.keywords)
    assert_equal(Set["amd64", "~arm64"], pkg.keywords)
  end

  def test_iuse
    repo = EbuildTemp.new
    # none
    pkg = repo.create_pkg("cat/pkg-1")
    assert_empty(pkg.iuse)

    # single
    pkg = repo.create_pkg("cat/pkg-1", "IUSE=a")
    assert_equal(Set["a"], pkg.iuse)

    # multiple
    pkg = repo.create_pkg("cat/pkg-1", "IUSE=a b c")
    refute_empty(pkg.iuse)
    assert_equal(Set["a", "b", "c"], pkg.iuse)
  end

  def test_inherits
    repo = EbuildTemp.new
    # none
    pkg = repo.create_pkg("cat/pkg-1")
    assert_empty(pkg.inherit)
    assert_empty(pkg.inherited)
    # TODO: add eclass inherit tests
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

  def test_hash
    repo = EbuildTemp.new
    TOML["version"]["hashing"].each do |d|
      pkgs = Set.new(d["versions"].map { |s| repo.create_pkg("cat/pkg-#{s}") }.compact)
      length = d["equal"] ? 1 : d["versions"].length
      assert_equal(pkgs.length, length)
    end
  end

  def test_string
    repo = EbuildTemp.new(id: "repo")
    pkg = repo.create_pkg("cat/pkg-1")
    assert_equal("cat/pkg-1::repo", pkg.to_s)
    assert_includes(pkg.inspect, "cat/pkg-1::repo")
  end
end
