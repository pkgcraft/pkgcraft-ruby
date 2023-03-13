# frozen_string_literal: true

require "test_helper"

class TestPkgcraft < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil Pkgcraft::VERSION
  end

  def test_pkgcraft_c_version
    version = Gem::Version.new(C.pkgcraft_lib_version)
    minver = Gem::Version.new(Pkgcraft::MINVER)
    maxver = Gem::Version.new(Pkgcraft::MAXVER)
    assert(version >= minver, "pkgcraft C library #{version} fails requirement >=#{minver}")
    assert(version <= maxver, "pkgcraft C library #{version} fails requirement <=#{maxver}")
  end
end
