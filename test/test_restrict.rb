# frozen_string_literal: true

require "test_helper"

class TestRestrict < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Dep
  include Pkgcraft::Repos
  include Pkgcraft::Restricts

  def test_eq_and_hash
    r1 = Restrict.new("cat/pkg-1")
    r2 = Restrict.new(Cpv.new("cat/pkg-1"))
    assert_equal(r1, r2)
    assert_equal(r2, r1)
    assert_equal(1, Set[r1, r2].length)
  end

  def test_logic_ops
    repo = EbuildTemp.new
    pkg1 = repo.create_pkg("cat/pkg-1")
    pkg2 = repo.create_pkg("cat/pkg-2")

    r1 = Restrict.new("cat/pkg-1")
    r2 = Restrict.new("cat/pkg-2")
    assert_equal([pkg1], repo.iter(r1).entries)
    assert_equal([pkg2], repo.iter(r2).entries)
    assert_equal([pkg2], repo.iter(~r1).entries)
    assert_equal([pkg1], repo.iter(~r2).entries)
    assert_empty(repo.iter(r1 & r2).entries)
    assert_equal([pkg1, pkg2], repo.iter(r1 | r2).entries)
    assert_equal([pkg1, pkg2], repo.iter(r1 ^ r2).entries)
    assert_equal([pkg1, pkg2], repo.iter(~(r1 & r2)).entries)
    assert_empty(repo.iter(~(r1 | r2)).entries)
    assert_empty(repo.iter(~(r1 ^ r2)).entries)

    # invalid type
    assert_raises TypeError do
      assert(r1 & nil)
    end
    assert_raises TypeError do
      assert(r1 | nil)
    end
    assert_raises TypeError do
      assert(r1 ^ nil)
    end
  end
end
