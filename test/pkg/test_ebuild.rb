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
    assert_equal(Cpn.new("cat/pkg"), pkg.cpn)
  end

  def test_eapi
    # default
    repo = EbuildTemp.new
    pkg = repo.create_pkg("cat/pkg-1")
    assert_equal(EAPI_LATEST_OFFICIAL, pkg.eapi)

    # explicit
    pkg = repo.create_pkg("cat/pkg-1", "EAPI=7")
    refute_nil(pkg.eapi)
    assert_equal(EAPI7, pkg.eapi)
  end

  def test_repo
    repo = EbuildTemp.new
    pkg = repo.create_pkg("cat/pkg-1")
    refute_nil(pkg.repo)
    assert_equal(repo, pkg.repo)
  end

  def test_version
    repo = EbuildTemp.new
    pkg = repo.create_pkg("cat/pkg-1")
    refute_nil(pkg.version)
    assert_equal(Version.new("1"), pkg.version)
  end

  def test_intersects
    repo = EbuildTemp.new(id: "test")
    pkg = repo.create_pkg("cat/pkg-1-r2", "SLOT=0/1")

    # Dep intersections
    assert(pkg.intersects(Dep.new("cat/pkg")))
    refute(pkg.intersects(Dep.new("a/b")))
    assert(pkg.intersects(Dep.new("=cat/pkg-1-r2")))
    refute(pkg.intersects(Dep.new(">cat/pkg-1-r2")))
    assert(pkg.intersects(Dep.new("cat/pkg:0")))
    refute(pkg.intersects(Dep.new("cat/pkg:1")))
    assert(pkg.intersects(Dep.new("cat/pkg:0/1")))
    refute(pkg.intersects(Dep.new("cat/pkg:0/2")))
    assert(pkg.intersects(Dep.new("cat/pkg::test")))
    refute(pkg.intersects(Dep.new("cat/pkg::repo")))

    # Cpv intersections
    assert(pkg.intersects(Cpv.new("cat/pkg-1-r2")))
    refute(pkg.intersects(Cpv.new("cat/pkg-1")))

    # Cpn intersections
    assert(pkg.intersects(Cpn.new("cat/pkg")))
    refute(pkg.intersects(Cpn.new("a/b")))

    # invalid types
    ["", nil].each do |obj|
      assert_raises TypeError do
        pkg.intersects(obj)
      end
    end
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
      assert_empty(pkg.send(attr))

      # empty
      pkg = repo.create_pkg("cat/pkg-1", "#{attr.upcase}=")
      assert_empty(pkg.send(attr))

      # defined
      pkg = repo.create_pkg("cat/pkg-1", "#{attr.upcase}=cat/pkg")
      refute_nil(pkg.send(attr))
      assert_equal(DependencySet.package("cat/pkg"), pkg.send(attr))
    end
  end

  def test_license
    # none
    pkg = TESTDATA_CONFIG.repos["metadata"]["optional/none-8"]
    assert_empty(pkg.license)

    # empty
    pkg = TESTDATA_CONFIG.repos["metadata"]["optional/empty-8"]
    assert_empty(pkg.license)

    # single-line
    pkg = TESTDATA_CONFIG.repos["metadata"]["license/single-8"]
    assert_equal(DependencySet.license("l1 l2"), pkg.license)

    # multi-line
    pkg = TESTDATA_CONFIG.repos["metadata"]["license/multi-8"]
    assert_equal(DependencySet.license("l1 u? ( l2 )"), pkg.license)

    # inherited and overridden
    pkg = TESTDATA_CONFIG.repos["metadata"]["license/inherit-8"]
    assert_equal(DependencySet.license("l1"), pkg.license)

    # inherited and appended
    pkg = TESTDATA_CONFIG.repos["metadata"]["license/append-8"]
    assert_equal(DependencySet.license("l2 l1"), pkg.license)
  end

  def test_properties
    repo = EbuildTemp.new
    # undefined
    pkg = repo.create_pkg("cat/pkg-1")
    assert_empty(pkg.properties)

    # empty
    pkg = repo.create_pkg("cat/pkg-1", "PROPERTIES=")
    assert_empty(pkg.properties)

    # defined
    pkg = repo.create_pkg("cat/pkg-1", "PROPERTIES=live")
    refute_nil(pkg.properties)
    assert_equal(DependencySet.properties("live"), pkg.properties)
  end

  def test_required_use
    repo = EbuildTemp.new
    # undefined
    pkg = repo.create_pkg("cat/pkg-1")
    assert_empty(pkg.required_use)

    # empty
    pkg = repo.create_pkg("cat/pkg-1", "REQUIRED_USE=")
    assert_empty(pkg.required_use)

    # defined
    pkg = repo.create_pkg("cat/pkg-1", "REQUIRED_USE=u1? ( u2 )")
    refute_nil(pkg.required_use)
    assert_equal(DependencySet.required_use("u1? ( u2 )"), pkg.required_use)
  end

  def test_restrict
    repo = EbuildTemp.new
    # undefined
    pkg = repo.create_pkg("cat/pkg-1")
    assert_empty(pkg.restrict)

    # empty
    pkg = repo.create_pkg("cat/pkg-1", "RESTRICT=")
    assert_empty(pkg.restrict)

    # defined
    pkg = repo.create_pkg("cat/pkg-1", "RESTRICT=test")
    refute_nil(pkg.restrict)
    assert_equal(DependencySet.restrict("test"), pkg.restrict)
  end

  def test_src_uri
    repo = EbuildTemp.new
    # undefined
    pkg = repo.create_pkg("cat/pkg-1")
    assert_empty(pkg.src_uri)

    # empty
    pkg = repo.create_pkg("cat/pkg-1", "SRC_URI=")
    assert_empty(pkg.src_uri)

    # defined
    pkg = repo.create_pkg("cat/pkg-1", "SRC_URI=https://a.com/file.tar.gz")
    refute_nil(pkg.src_uri)
    assert_equal(DependencySet.src_uri("https://a.com/file.tar.gz"), pkg.src_uri)
  end

  def test_defined_phases
    repo = EbuildTemp.new
    # none
    pkg = repo.create_pkg("cat/pkg-1")
    assert_empty(pkg.defined_phases)

    # single
    data = "src_configure() { :; }"
    pkg = repo.create_pkg("cat/pkg-1", data:)
    assert_equal(Set["src_configure"], pkg.defined_phases)

    # multiple
    data = <<~PHASES
      src_prepare() { :; }
      src_configure() { :; }
      src_compile() { :; }
    PHASES
    pkg = repo.create_pkg("cat/pkg-1", data:)
    refute_empty(pkg.defined_phases)
    assert_equal(Set["src_prepare", "src_configure", "src_compile"], pkg.defined_phases)
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
    # none
    pkg = TESTDATA_CONFIG.repos["metadata"]["optional/none-8"]
    assert_empty(pkg.keywords)

    # empty
    pkg = TESTDATA_CONFIG.repos["metadata"]["optional/empty-8"]
    assert_empty(pkg.keywords)

    # single line
    pkg = TESTDATA_CONFIG.repos["metadata"]["keywords/single-8"]
    assert_equal(Set["amd64", "~arm64"], pkg.keywords)

    # single line
    pkg = TESTDATA_CONFIG.repos["metadata"]["keywords/multi-8"]
    assert_equal(Set["~amd64", "arm64"], pkg.keywords)
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
    # none
    pkg = TESTDATA_CONFIG.repos["metadata"]["optional/none-8"]
    assert_empty(pkg.inherit)
    assert_empty(pkg.inherited)

    # direct inherit
    pkg = TESTDATA_CONFIG.repos["metadata"]["inherit/direct-8"]
    assert_equal(Set["a"], pkg.inherit)
    assert_equal(Set["a"], pkg.inherited)

    # indirect inherit
    pkg = TESTDATA_CONFIG.repos["metadata"]["inherit/indirect-8"]
    assert_equal(Set["b"], pkg.inherit)
    assert_equal(Set["b", "a"], pkg.inherited)
  end

  def test_long_description
    repo = EbuildTemp.new
    # none
    pkg = repo.create_pkg("cat/pkg-1")
    assert_nil(pkg.long_description)
  end

  def test_cmp
    repo = EbuildTemp.new
    pkg1 = repo.create_pkg("cat/pkg-1")
    pkg2 = repo.create_pkg("cat/pkg-2")
    pkg3 = repo.create_pkg("cat/pkg-1-r0")
    assert_operator(pkg1, :<, pkg2)
    assert_operator(pkg1, :<=, pkg2)
    assert_equal(pkg1, pkg3)
    refute_equal(pkg1, pkg2)
    assert_operator(pkg2, :>=, pkg1)
    assert_operator(pkg2, :>, pkg1)

    # invalid type
    assert_raises TypeError do
      pkg1 < "cat/pkg-1"
    end
  end

  def test_hash
    repo = EbuildTemp.new
    TESTDATA_TOML["version"]["hashing"].each do |d|
      set = Set.new(d["versions"].map { |s| repo.create_pkg("cat/pkg-#{s}") }.compact)
      length = d["equal"] ? 1 : d["versions"].length
      assert_includes(set, set.entries.first)
      assert_equal(set.length, length)
    end
  end

  def test_string
    repo = EbuildTemp.new(id: "repo")
    pkg = repo.create_pkg("cat/pkg-1")
    assert_equal("cat/pkg-1::repo", pkg.to_s)
    assert_includes(pkg.inspect, "cat/pkg-1::repo")
  end
end
