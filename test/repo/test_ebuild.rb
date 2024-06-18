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
    repo = EbuildTemp.new(eapi: EAPI7)
    refute_nil(repo.eapi)
    assert_equal(EAPI7, repo.eapi)
  end

  def test_masters
    # primary repo
    primary_repo = TESTDATA_CONFIG.repos["primary"]
    assert_empty(primary_repo.masters)

    # dependent repo
    secondary_repo = TESTDATA_CONFIG.repos["secondary"]
    refute_empty(secondary_repo.masters)
    assert_equal([primary_repo], secondary_repo.masters)
  end
end
