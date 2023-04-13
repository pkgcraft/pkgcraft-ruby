# frozen_string_literal: true

require "test_helper"

class TestRepoFake < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Eapis
  include Pkgcraft::Repos

  def test_new
    # empty
    repo = Fake.new
    assert_empty(repo)

    # single
    repo = Fake.new(["cat/pkg-1"])
    refute_empty(repo)
  end
end
