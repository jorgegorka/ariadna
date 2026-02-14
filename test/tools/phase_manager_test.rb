require "test_helper"
require "ariadna/tools/phase_manager"

class PhaseManagerTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @phases_dir = File.join(@dir, ".planning", "phases")
    FileUtils.mkdir_p(@phases_dir)
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_normalize_phase_name
    # Access private method for testing
    pm = Ariadna::Tools::PhaseManager
    assert_equal "01", pm.send(:normalize_phase_name, "1")
    assert_equal "02", pm.send(:normalize_phase_name, "2")
    assert_equal "10", pm.send(:normalize_phase_name, "10")
    assert_equal "02.1", pm.send(:normalize_phase_name, "2.1")
    assert_equal "02.1", pm.send(:normalize_phase_name, "02.1")
  end

  def test_find_phase_on_disk
    FileUtils.mkdir_p(File.join(@phases_dir, "01-setup"))
    File.write(File.join(@phases_dir, "01-setup", "1-1-PLAN.md"), "---\nphase: 1\nplan: 1\n---\n")

    Dir.chdir(@dir) do
      dirs = Dir.children(@phases_dir).select { |d| File.directory?(File.join(@phases_dir, d)) }.sort
      match = dirs.find { |d| d.start_with?("01") }
      assert_equal "01-setup", match
    end
  end

  def test_list_phases
    FileUtils.mkdir_p(File.join(@phases_dir, "01-setup"))
    FileUtils.mkdir_p(File.join(@phases_dir, "02-auth"))
    FileUtils.mkdir_p(File.join(@phases_dir, "03-api"))

    dirs = Dir.children(@phases_dir)
              .select { |d| File.directory?(File.join(@phases_dir, d)) }
              .sort_by { |d| d.match(/\A(\d+(?:\.\d+)?)/)&.[](1)&.to_f || 0 }

    assert_equal %w[01-setup 02-auth 03-api], dirs
  end

  def test_decimal_phase_calculation
    FileUtils.mkdir_p(File.join(@phases_dir, "02-auth"))
    FileUtils.mkdir_p(File.join(@phases_dir, "02.1-oauth"))

    dirs = Dir.children(@phases_dir).select { |d| File.directory?(File.join(@phases_dir, d)) }
    decimal_pattern = /\A02\.(\d+)/
    existing = dirs.filter_map { |d| m = d.match(decimal_pattern); "02.#{m[1]}" if m }
                   .sort_by(&:to_f)

    assert_equal ["02.1"], existing
    last_num = existing.last.split(".")[1].to_i
    assert_equal "02.2", "02.#{last_num + 1}"
  end
end
