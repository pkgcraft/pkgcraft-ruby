# frozen_string_literal: true

require "test_helper"

class TestEapi < Minitest::Test
  def test_eapis
    # verify objects are shared between EAPIS_OFFICIAL and EAPIS
    assert(Pkgcraft::Eapi.EAPIS.length > Pkgcraft::Eapi.EAPIS_OFFICIAL.length)
    Pkgcraft::Eapi.EAPIS_OFFICIAL.each do |id, eapi|
      assert(eapi.equal?(Pkgcraft::Eapi.EAPIS[id]))
    end

    eapi_latest = Pkgcraft::Eapi.latest
    eapi_latest_official = Pkgcraft::Eapi.latest_official
    assert(Pkgcraft::Eapi.EAPIS[eapi_latest_official.to_s].equal?(eapi_latest_official))
    assert(Pkgcraft::Eapi.EAPIS[eapi_latest.to_s].equal?(eapi_latest))
    assert(!eapi_latest_official.equal?(eapi_latest))
  end

  def test_has
    assert(!Pkgcraft::Eapi.latest.has("nonexistent_feature"))
    assert(!Pkgcraft::Eapi.EAPIS["0"].has("slot_deps"))
    assert(Pkgcraft::Eapi.EAPIS["1"].has("slot_deps"))
    assert(!Pkgcraft::Eapi.EAPIS["1"].has(nil))
  end
end
