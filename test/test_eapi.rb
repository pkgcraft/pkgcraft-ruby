# frozen_string_literal: true

require "test_helper"

class TestEapi < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Eapis
  include Pkgcraft::Error

  def test_eapis
    # verify objects are shared between EAPIS_OFFICIAL and EAPIS
    assert(EAPIS.length > EAPIS_OFFICIAL.length)
    EAPIS_OFFICIAL.each do |id, eapi|
      assert(eapi.equal?(EAPIS[id]))
    end

    eapi_latest = EAPI_LATEST
    eapi_latest_official = EAPI_LATEST_OFFICIAL
    assert(EAPIS[eapi_latest_official.to_s].equal?(eapi_latest_official))
    assert(EAPIS[eapi_latest.to_s].equal?(eapi_latest))
    assert(!eapi_latest_official.equal?(eapi_latest))
  end

  def test_from_obj
    assert(Eapi.from_obj(EAPI0).equal?(EAPI0))
    assert(Eapi.from_obj("0").equal?(EAPI0))

    # unknown
    assert_raises RuntimeError do
      Eapi.from_obj("unknown")
    end

    # invalid
    assert_raises TypeError do
      Eapi.from_obj(nil)
    end
  end

  def test_range
    eapis = Eapis.range("..")
    assert_equal(eapis, EAPIS.values)

    eapis = Eapis.range("..2")
    assert_equal(eapis, [EAPI0, EAPI1])

    eapis = Eapis.range("1..2")
    assert_equal(eapis, [EAPI1])

    assert_raises PkgcraftError do
      Eapis.range("..9999")
    end
  end

  def test_has
    assert(!EAPI_LATEST.has("nonexistent_feature"))
    assert(!EAPI0.has("slot_deps"))
    assert(EAPI1.has("slot_deps"))
    assert(!EAPI1.has(nil))
  end

  def test_cmp
    latest = EAPI_LATEST
    latest_official = EAPI_LATEST_OFFICIAL
    assert(EAPI0 < EAPI1)
    assert(latest_official > EAPI1)
    assert(latest >= latest_official)
  end

  def test_hash
    # equal
    eapis = Set.new([EAPI0, EAPI0])
    assert_equal(eapis.length, 1)

    # unequal
    eapis = Set.new([EAPI0, EAPI1])
    assert_equal(eapis.length, 2)
  end
end
