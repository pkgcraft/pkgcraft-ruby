# frozen_string_literal: true

require "set"

require "test_helper"

class TestCpn < Minitest::Test
  include Pkgcraft::Dep
  include Pkgcraft::Error

  def test_new
    cpn = Cpn.new("cat/pkg")
    assert_equal("cat", cpn.category)
    assert_equal("pkg", cpn.package)

    # invalid
    ["cat/pkg-1", "=cat/pkg-1", "", nil].each do |s|
      assert_raises InvalidCpn do
        Cpn.new(s)
      end
    end
  end
end
