# frozen_string_literal: true

require "test_helper"

class TestPkgEbuild < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Dep
  include Pkgcraft::Eapis
  include Pkgcraft::Repo

  def test_eapi
    # default
    repo = EbuildTemp.new("test")
    pkg = repo.create_pkg("cat/pkg-1")
    assert_equal(EAPI_LATEST_OFFICIAL, pkg.eapi)

    # explicit
    pkg = repo.create_pkg("cat/pkg-1", "EAPI=5")
    assert_equal(EAPI5, pkg.eapi)
  end

  def test_cpv
    repo = EbuildTemp.new("test")
    pkg = repo.create_pkg("cat/pkg-1")
    assert_equal(Cpv.new("cat/pkg-1"), pkg.cpv)

    # explicit
    pkg = repo.create_pkg("cat/pkg-1", "EAPI=5")
    assert_equal(EAPI5, pkg.eapi)
  end
end
