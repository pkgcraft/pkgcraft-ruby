# frozen_string_literal: true

require "test_helper"

class TestRepoSet < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Eapis
  include Pkgcraft::Repos

  def test_new
    # empty
    set = RepoSet.new
    assert_empty(set.repos)

    # single
    r1 = EbuildTemp.new("r1")
    set = RepoSet.new(r1)
    assert_equal(Set[r1], set.repos)
  end
end
