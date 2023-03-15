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

  def test_from_obj
    eapi0 = Pkgcraft::Eapi.EAPIS["0"]
    assert(Pkgcraft::Eapi.from_obj(eapi0).equal?(eapi0))
    assert(Pkgcraft::Eapi.from_obj("0").equal?(eapi0))

    # unknown
    assert_raises RuntimeError do
      Pkgcraft::Eapi.from_obj("unknown")
    end

    # invalid
    assert_raises TypeError do
      Pkgcraft::Eapi.from_obj(nil)
    end
  end

  def test_has
    assert(!Pkgcraft::Eapi.latest.has("nonexistent_feature"))
    assert(!Pkgcraft::Eapi.EAPIS["0"].has("slot_deps"))
    assert(Pkgcraft::Eapi.EAPIS["1"].has("slot_deps"))
    assert(!Pkgcraft::Eapi.EAPIS["1"].has(nil))
  end

  def test_cmp
    eapi0 = Pkgcraft::Eapi.EAPIS["0"]
    eapi1 = Pkgcraft::Eapi.EAPIS["1"]
    latest = Pkgcraft::Eapi.latest
    latest_official = Pkgcraft::Eapi.latest_official
    assert(eapi0 < eapi1)
    assert(latest_official > eapi1)
    assert(latest >= latest_official)
  end

  def test_hash
    eapi0 = Pkgcraft::Eapi.EAPIS["0"]
    eapi1 = Pkgcraft::Eapi.EAPIS["1"]

    # equal
    eapis = Set.new([eapi0, eapi0])
    assert_equal(eapis.length, 1)

    # unequal
    eapis = Set.new([eapi0, eapi1])
    assert_equal(eapis.length, 2)
  end
end
