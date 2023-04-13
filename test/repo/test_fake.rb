# frozen_string_literal: true

require "test_helper"

class TestRepoFake < Minitest::Test
  include Pkgcraft
  include Pkgcraft::Config
  include Pkgcraft::Error
  include Pkgcraft::Repos

  def test_new
    # empty
    repo = Fake.new
    assert_empty(repo)

    # single
    repo = Fake.new(["cat/pkg-1"])
    refute_empty(repo)

    # file path
    f = Tempfile.new("cpvs")
    f.write("cat/pkg-1")
    f.rewind
    repo = Fake.new(f.path)
    refute_empty(repo)
  end

  def test_extend
    repo = Fake.new
    assert_empty(repo)

    # empty
    repo.extend([])
    assert_empty(repo)

    # invalid CPVs are ignored
    repo.extend(["=cat/pkg-1"])
    assert_empty(repo)

    # single
    repo.extend(["cat/pkg-1"])
    refute_empty(repo)

    config = Config.new
    config.add_repo(repo)
    assert_raises PkgcraftError do
      repo.extend(["cat/pkg-2"])
    end
  end
end
