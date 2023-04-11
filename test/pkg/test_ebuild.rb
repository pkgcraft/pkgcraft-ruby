# frozen_string_literal: true

require "test_helper"

class TestPkgEbuild < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Eapis
  include Pkgcraft::Repo

  def test_eapi
    # default
    repo = EbuildTemp.new("test")
    repo.create_ebuild("cat/pkg-1")
    assert_equal(EAPI_LATEST_OFFICIAL, repo.first.eapi)

    # explicit
    repo.create_ebuild("cat/pkg-1", "EAPI=5")
    assert_equal(EAPI5, repo.first.eapi)
  end
end
