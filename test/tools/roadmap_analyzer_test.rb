# frozen_string_literal: true

require "test_helper"
require "ariadna/tools/roadmap_analyzer"

class RoadmapAnalyzerTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @planning_dir = File.join(@dir, ".planning")
    @phases_dir = File.join(@planning_dir, "phases")
    FileUtils.mkdir_p(@phases_dir)
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_get_phase_finds_phase_in_roadmap
    roadmap = <<~MD
      # ROADMAP

      ## v1.0: MVP

      ### Phase 1: Setup

      **Goal:** Set up the project skeleton

      ### Phase 2: Core Features

      **Goal:** Build the core functionality
    MD
    File.write(File.join(@planning_dir, "ROADMAP.md"), roadmap)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::RoadmapAnalyzer.get_phase("1") }
      assert result[:found]
      assert_equal "1", result[:phase_number]
      assert_includes result[:phase_name], "Setup"
      assert_equal "Set up the project skeleton", result[:goal]
      assert_includes result[:section], "Phase 1"
    end
  end

  def test_get_phase_not_found
    File.write(File.join(@planning_dir, "ROADMAP.md"), "# ROADMAP\n\n### Phase 1: Setup\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::RoadmapAnalyzer.get_phase("99") }
      refute result[:found]
    end
  end

  def test_get_phase_no_roadmap
    Dir.chdir(@dir) do
      FileUtils.rm_f(File.join(@planning_dir, "ROADMAP.md"))
      result = capture_json { Ariadna::Tools::RoadmapAnalyzer.get_phase("1") }
      refute result[:found]
      assert_equal "ROADMAP.md not found", result[:error]
    end
  end

  def test_analyze_roadmap
    roadmap = <<~MD
      # ROADMAP

      ## v1.0: MVP Release

      ### Phase 1: Setup

      **Goal:** Project skeleton
      **Depends on:** Nothing

      ### Phase 2: Auth

      **Goal:** Authentication system
      **Depends on:** Phase 1
    MD
    File.write(File.join(@planning_dir, "ROADMAP.md"), roadmap)

    # Phase 1 has a plan and summary (complete)
    phase1_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase1_dir)
    File.write(File.join(phase1_dir, "01-01-PLAN.md"), "---\nphase: 1\nplan: 01\n---\n")
    File.write(File.join(phase1_dir, "01-01-SUMMARY.md"), "---\nphase: 1\nplan: 01\n---\n")

    # Phase 2 has only a plan (planned)
    phase2_dir = File.join(@phases_dir, "02-auth")
    FileUtils.mkdir_p(phase2_dir)
    File.write(File.join(phase2_dir, "02-01-PLAN.md"), "---\nphase: 2\nplan: 01\n---\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::RoadmapAnalyzer.analyze }
      assert_equal 2, result[:phase_count]
      assert_equal 1, result[:completed_phases]
      assert_equal 2, result[:total_plans]
      assert_equal 1, result[:total_summaries]
      assert_equal 50, result[:progress_percent]

      phase1 = result[:phases].find { |p| p[:number] == "1" }
      assert_equal "complete", phase1[:disk_status]
      assert_equal "Project skeleton", phase1[:goal]

      phase2 = result[:phases].find { |p| p[:number] == "2" }
      assert_equal "planned", phase2[:disk_status]

      assert_equal "2", result[:current_phase]
    end
  end

  def test_analyze_extracts_milestones
    roadmap = "# ROADMAP\n\n## v1.0: First Release\n\n### Phase 1: Setup\n\n**Goal:** TBD\n"
    File.write(File.join(@planning_dir, "ROADMAP.md"), roadmap)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::RoadmapAnalyzer.analyze }
      assert_equal 1, result[:milestones].length
      assert_equal "v1.0", result[:milestones].first[:version]
    end
  end

  def test_progress_json_format
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-PLAN.md"), "plan")
    File.write(File.join(phase_dir, "01-01-SUMMARY.md"), "summary")

    File.write(File.join(@planning_dir, "ROADMAP.md"), "# ROADMAP\n\n## v1.0: MVP\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::RoadmapAnalyzer.progress(["json"]) }
      assert_equal 1, result[:total_plans]
      assert_equal 1, result[:total_summaries]
      assert_equal 100, result[:percent]
      assert_equal "v1.0", result[:milestone_version]
    end
  end

  def test_progress_bar_format
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-PLAN.md"), "plan")

    File.write(File.join(@planning_dir, "ROADMAP.md"), "# ROADMAP\n\n## v1.0: MVP\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::RoadmapAnalyzer.progress(["bar"]) }
      assert_equal 0, result[:percent]
      assert_includes result[:bar], "0/1 plans"
    end
  end

  def test_progress_table_format
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-PLAN.md"), "plan")
    File.write(File.join(phase_dir, "01-01-SUMMARY.md"), "summary")

    File.write(File.join(@planning_dir, "ROADMAP.md"), "# ROADMAP\n\n## v1.0: MVP\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::RoadmapAnalyzer.progress(["table"]) }
      assert_includes result[:rendered], "Phase"
      assert_includes result[:rendered], "Status"
      assert_includes result[:rendered], "100%"
    end
  end

  private

  def capture_json(&block)
    output = capture_output(&block)
    JSON.parse(output, symbolize_names: true)
  end

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
end
