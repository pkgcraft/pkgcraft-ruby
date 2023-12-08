# frozen_string_literal: true

require "test_helper"

class TestDependency < Minitest::Test
  include Pkgcraft::Dep

  def test_iter_flatten
    # single
    dep = Package.new("cat/pkg").entries.first
    assert_equal(["cat/pkg"], dep.iter_flatten.map(&:to_s))
    dep = Package.new("u? ( a/b )").entries.first
    assert_equal(["a/b"], dep.iter_flatten.map(&:to_s))
    assert_includes(dep.inspect, dep.to_s)

    # multiple nested
    dep = Package.new("u? ( || ( a/b c/d ) e/f )").entries.first
    assert_equal(["a/b", "c/d", "e/f"], dep.iter_flatten.map(&:to_s))
  end

  def test_iter_recursive
    # single
    dep = Package.new("cat/pkg").entries.first
    assert_equal(["cat/pkg"], dep.iter_recursive.map(&:to_s))
    dep = Package.new("u? ( a/b )").entries.first
    assert_equal(["u? ( a/b )", "a/b"], dep.iter_recursive.map(&:to_s))

    # multiple nested
    dep = Package.new("u? ( || ( a/b c/d ) e/f )").entries.first
    assert_equal(
      ["u? ( || ( a/b c/d ) e/f )", "|| ( a/b c/d )", "a/b", "c/d", "e/f"],
      dep.iter_recursive.map(&:to_s)
    )
  end
end

class TestPackage < Minitest::Test
  include Pkgcraft::Dep
  include Pkgcraft::Error

  def test_string
    # no args
    dep = Package.new
    assert_equal(0, dep.length)
    assert_empty(dep)
    assert_empty(dep.to_s)
    assert_includes(dep.inspect, dep.to_s)

    ["", "a/b"].each do |s|
      dep = Package.new(s)
      assert_equal(s, dep.to_s)
    end
  end

  def test_invalid
    assert_raises PkgcraftError do
      Package.new("u? ( cat/pkg)")
    end
  end

  def test_eq_and_hash
    [
      ["a/dep", "a/dep"],
      ["a/b c/d", "c/d a/b"]
    ].each do |s1, s2|
      dep1 = Package.new(s1)
      dep2 = Package.new(s2)
      assert_equal(dep1, dep2)
      set = Set[dep1, dep2]
      assert_equal(1, set.length)
      assert_includes(set, dep2)

      # invalid type
      assert_raises TypeError do
        dep1 == ""
      end
    end
  end

  def test_iter
    # empty
    dep = Package.new
    assert_empty(dep.entries)

    # single
    dep = Package.new("cat/pkg")
    assert_equal(["cat/pkg"], dep.map(&:to_s))

    # multiple
    dep = Package.new("a/b u? ( c/d )")
    assert_equal(["a/b", "u? ( c/d )"], dep.map(&:to_s))
  end

  def test_iter_flatten
    # empty
    dep = Package.new
    assert_empty(dep.iter_flatten.entries)

    # single
    dep = Package.new("cat/pkg")
    assert_equal(["cat/pkg"], dep.iter_flatten.map(&:to_s))

    # multiple
    dep = Package.new("a/b u? ( c/d )")
    assert_equal(["a/b", "c/d"], dep.iter_flatten.map(&:to_s))
  end

  def test_iter_recursive
    # empty
    dep = Package.new
    assert_empty(dep.iter_recursive.entries)

    # single
    dep = Package.new("cat/pkg")
    assert_equal(["cat/pkg"], dep.iter_flatten.map(&:to_s))

    # multiple
    dep = Package.new("a/b u? ( c/d )")
    assert_equal(["a/b", "u? ( c/d )", "c/d"], dep.iter_recursive.map(&:to_s))
  end
end

class TestLicense < Minitest::Test
  include Pkgcraft::Dep
  include Pkgcraft::Error

  def test_iter_flatten
    # empty
    license = License.new
    assert_empty(license.iter_flatten.entries)

    # single
    license = License.new("BSD")
    assert_equal(["BSD"], license.iter_flatten.map(&:to_s))

    # multiple
    license = License.new("BSD u? ( GPL-3 )")
    assert_equal(["BSD", "GPL-3"], license.iter_flatten.map(&:to_s))
  end
end

class TestSrcUri < Minitest::Test
  include Pkgcraft::Dep
  include Pkgcraft::Error

  def test_uri
    # no rename
    uri = SrcUri.new("https://a.zip").iter_flatten.entries.first
    assert_equal("https://a.zip", uri.uri)
    assert_equal("a.zip", uri.filename)

    # rename
    uri = SrcUri.new("https://a.zip -> a-1.zip").iter_flatten.entries.first
    assert_equal("https://a.zip", uri.uri)
    assert_equal("a-1.zip", uri.filename)
  end

  def test_iter_flatten
    # empty
    uris = SrcUri.new
    assert_empty(uris.iter_flatten.entries)

    # single
    uris = SrcUri.new("https://a.com")
    assert_equal(["https://a.com"], uris.iter_flatten.map(&:to_s))

    # multiple
    uris = SrcUri.new("https://a.com u? ( https://b.com )")
    assert_equal(["https://a.com", "https://b.com"], uris.iter_flatten.map(&:to_s))
  end
end
