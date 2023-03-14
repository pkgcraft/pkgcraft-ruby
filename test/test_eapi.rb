# frozen_string_literal: true

require "test_helper"

class TestEapi < Minitest::Test
  def test_eapis
    # verify objects are shared between EAPIS_OFFICIAL and EAPIS
    assert(Pkgcraft::Eapi.EAPIS.length > Pkgcraft::Eapi.EAPIS_OFFICIAL.length)
    Pkgcraft::Eapi.EAPIS_OFFICIAL.each do |id, eapi|
      assert(eapi.equal?(Pkgcraft::Eapi.EAPIS[id]))
    end

    eapi_latest = Pkgcraft::Eapi.EAPI_LATEST
    eapi_latest_official = Pkgcraft::Eapi.EAPI_LATEST_OFFICIAL
    assert(Pkgcraft::Eapi.EAPIS[eapi_latest_official.to_s].equal?(eapi_latest_official))
    assert(Pkgcraft::Eapi.EAPIS[eapi_latest.to_s].equal?(eapi_latest))
    assert(!eapi_latest_official.equal?(eapi_latest))
  end
end
