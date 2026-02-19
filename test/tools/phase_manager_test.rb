require "test_helper"
require "ariadna/tools/phase_manager"

class PhaseManagerTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @phases_dir = File.join(@dir, ".ariadna_planning", "phases")
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

  def test_plan_index_enriched_output
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)

    plan1 = "---\nphase: 1\nplan: 01\nwave: 1\ntype: implementation\ndomain: backend\nautonomous: true\nobjective: Build API\ndepends_on: []\nfiles_modified: [app/models/user.rb]\n---\n<task name=\"create model\">content</task>\n"
    plan2 = "---\nphase: 1\nplan: 02\nwave: 1\ntype: implementation\ndomain: frontend\nobjective: Build UI\n---\n<task name=\"create view\">content</task>\n<task name=\"add styles\">more</task>\n"
    plan3 = "---\nphase: 1\nplan: 03\nwave: 2\ntype: implementation\ndomain: testing\nobjective: Write tests\n---\n<task name=\"test\">content</task>\n"

    File.write(File.join(phase_dir, "01-01-PLAN.md"), plan1)
    File.write(File.join(phase_dir, "01-02-PLAN.md"), plan2)
    File.write(File.join(phase_dir, "01-03-PLAN.md"), plan3)

    Dir.chdir(@dir) do
      output = capture_output { Ariadna::Tools::PhaseManager.plan_index(["1"], raw: true) }
      result = JSON.parse(output, symbolize_names: true)

      assert_equal 3, result[:count]
      assert_equal true, result[:multi_domain]
      assert_equal true, result[:recommend_team]
      assert_equal 3, result[:domain_count]
      assert_includes result[:domains], "backend"
      assert_includes result[:domains], "frontend"
      assert_includes result[:domains], "testing"

      backend_plan = result[:plans].find { |p| p[:domain] == "backend" }
      assert_equal "backend", backend_plan[:domain]
      assert_equal "true", backend_plan[:autonomous]
      assert_equal "Build API", backend_plan[:objective]
      assert_equal 1, backend_plan[:task_count]

      frontend_plan = result[:plans].find { |p| p[:domain] == "frontend" }
      assert_equal 2, frontend_plan[:task_count]
    end
  end

  def test_plan_index_single_domain_no_recommend
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)

    plan1 = "---\nphase: 1\nplan: 01\nwave: 1\ntype: implementation\ndomain: backend\n---\n"
    plan2 = "---\nphase: 1\nplan: 02\nwave: 1\ntype: implementation\ndomain: backend\n---\n"

    File.write(File.join(phase_dir, "01-01-PLAN.md"), plan1)
    File.write(File.join(phase_dir, "01-02-PLAN.md"), plan2)

    Dir.chdir(@dir) do
      output = capture_output { Ariadna::Tools::PhaseManager.plan_index(["1"], raw: true) }
      result = JSON.parse(output, symbolize_names: true)

      assert_equal false, result[:multi_domain]
      assert_equal false, result[:recommend_team]
      assert_equal 1, result[:domain_count]
    end
  end

  def test_plan_index_defaults_domain_to_general
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)

    plan = "---\nphase: 1\nplan: 01\nwave: 1\ntype: implementation\n---\n"
    File.write(File.join(phase_dir, "01-01-PLAN.md"), plan)

    Dir.chdir(@dir) do
      output = capture_output { Ariadna::Tools::PhaseManager.plan_index(["1"], raw: true) }
      result = JSON.parse(output, symbolize_names: true)

      assert_equal "general", result[:plans].first[:domain]
      assert_equal 0, result[:domain_count]
      assert_equal false, result[:multi_domain]
    end
  end

  private

  def capture_output
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
  rescue SystemExit
    # Output.json calls exit(0)
  ensure
    result = $stdout.string
    $stdout = old_stdout
    return result
  end

  public

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
