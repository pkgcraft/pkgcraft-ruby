# frozen_string_literal: true

require "test_helper"

class TestPkgcraft < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil Pkgcraft::VERSION
  end

  def test_pkgcraft_c_version
    version = Pkgcraft::C.version
    minver = Gem::Version.new(Pkgcraft::C::MINVER)
    maxver = Gem::Version.new(Pkgcraft::C::MAXVER)
    assert(version >= minver, "pkgcraft C library #{version} fails requirement >=#{minver}")
    assert(version <= maxver, "pkgcraft C library #{version} fails requirement <=#{maxver}")
  end
end
