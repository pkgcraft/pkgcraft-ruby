# frozen_string_literal: true

require "test_helper"

class TestRepoEbuild < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Eapis
  include Pkgcraft::Repos

  def test_eapi
    # default
    repo = EbuildTemp.new
    assert_equal(EAPI_LATEST_OFFICIAL, repo.eapi)

    # explicit
    repo = EbuildTemp.new(eapi: EAPI5)
    assert_equal(EAPI5, repo.eapi)
  end

  def test_masters
    repo = EbuildTemp.new
    assert_empty(repo.masters)
  end
end
