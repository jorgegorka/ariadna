require "test_helper"

class AriadnaTest < Minitest::Test
  def test_has_version_number
    refute_nil Ariadna::VERSION
    assert_match(/\A\d+\.\d+\.\d+\z/, Ariadna::VERSION)
  end

  def test_gem_root
    assert_equal File.expand_path("../..", __FILE__), Ariadna.gem_root
  end

  def test_data_dir
    assert Ariadna.data_dir.end_with?("/data")
    assert File.directory?(Ariadna.data_dir)
  end
end
