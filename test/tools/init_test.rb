require "test_helper"
require "ariadna/tools/init"

class InitTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @planning_dir = File.join(@dir, ".ariadna_planning")
    @phases_dir = File.join(@planning_dir, "phases")
    @memory_dir = File.join(@planning_dir, "memory")
    FileUtils.mkdir_p(@phases_dir)
    FileUtils.mkdir_p(@memory_dir)

    # Create minimal ROADMAP.md for milestone info
    File.write(File.join(@planning_dir, "ROADMAP.md"),
               "# ROADMAP\n\n## v1.0: MVP Release\n\n### Phase 1: Setup\n\n**Goal:** TBD\n")
    File.write(File.join(@planning_dir, "config.json"), '{"model_profile":"balanced"}')
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  # --- execute-phase ---

  def test_execute_phase_returns_paths_not_content # rubocop:disable Metrics/AbcSize
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-PLAN.md"),
               "---\nphase: 1\nplan: 01\ndomain: backend\nwave: 1\n---\n# Plan\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(%w[execute-phase 1]) }
      assert result[:phase_found]
      assert_equal ".ariadna_planning/phases/01-setup", result[:phase_dir]
      assert_equal "01", result[:phase_number]
      assert_equal "setup", result[:phase_name]

      # Must NOT contain file contents
      refute result.key?(:state_content)
      refute result.key?(:roadmap_content)
      refute result.key?(:state_path)

      # Must return memory_dir
      assert_equal ".ariadna_planning/memory", result[:memory_dir]

      # Must return inline config
      assert result.key?(:config)
      assert_equal "balanced", result[:config][:model_profile]

      # Must return executor_model
      assert_includes result[:executor_model], "sonnet"
    end
  end

  def test_execute_phase_plans_include_domain_and_wave
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-PLAN.md"),
               "---\nphase: 1\nplan: 01\ndomain: backend\nwave: 1\n---\n# Plan A\n")
    File.write(File.join(phase_dir, "01-02-PLAN.md"),
               "---\nphase: 1\nplan: 02\ndomain: frontend\nwave: 2\n---\n# Plan B\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(%w[execute-phase 1]) }
      plans = result[:plans]
      assert_equal 2, plans.length

      plan_a = plans.find { |p| p[:file] == "01-01-PLAN.md" }
      assert_equal "backend", plan_a[:domain]
      assert_equal "1", plan_a[:wave]

      plan_b = plans.find { |p| p[:file] == "01-02-PLAN.md" }
      assert_equal "frontend", plan_b[:domain]
      assert_equal "2", plan_b[:wave]
    end
  end

  def test_execute_phase_tracks_incomplete_plans
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-PLAN.md"),
               "---\nphase: 1\nplan: 01\ndomain: backend\nwave: 1\n---\n")
    File.write(File.join(phase_dir, "01-01-SUMMARY.md"), "done")
    File.write(File.join(phase_dir, "01-02-PLAN.md"),
               "---\nphase: 1\nplan: 02\ndomain: frontend\nwave: 1\n---\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(%w[execute-phase 1]) }
      assert_equal 2, result[:plan_count]
      assert_equal 1, result[:incomplete_count]
      assert_equal ["01-02-PLAN.md"], result[:incomplete_plans]
    end
  end

  def test_execute_phase_missing_phase_arg
    Dir.chdir(@dir) do
      assert_raises(SystemExit) do
        suppress_stderr { Ariadna::Tools::Init.dispatch(["execute-phase"]) }
      end
    end
  end

  # --- plan-phase ---

  def test_plan_phase_returns_paths_not_content
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(%w[plan-phase 1]) }
      assert result[:phase_found]
      assert_equal ".ariadna_planning/phases/01-setup", result[:phase_dir]

      # Must NOT contain file contents
      refute result.key?(:state_content)
      refute result.key?(:roadmap_content)
      refute result.key?(:requirements_content)
      refute result.key?(:context_content)
      refute result.key?(:research_content)

      # Must return memory_dir and config
      assert_equal ".ariadna_planning/memory", result[:memory_dir]
      assert result.key?(:config)

      # Must return planner_model
      assert result.key?(:planner_model)
    end
  end

  def test_plan_phase_returns_phase_metadata
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(%w[plan-phase 1]) }
      assert_equal "01", result[:phase_number]
      assert_equal "setup", result[:phase_name]
      assert_equal "01", result[:padded_phase]
    end
  end

  # --- verify-work ---

  def test_verify_work_returns_summary_paths # rubocop:disable Metrics/AbcSize
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-SUMMARY.md"), "summary 1")
    File.write(File.join(phase_dir, "01-02-SUMMARY.md"), "summary 2")
    File.write(File.join(phase_dir, "01-VERIFICATION.md"), "verification")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(%w[verify-work 1]) }
      assert result[:phase_found]
      assert result[:has_verification]

      # Must return summary_paths
      assert_equal 2, result[:summary_paths].length
      assert(result[:summary_paths].all? { |p| p.end_with?("-SUMMARY.md") })

      # Must NOT contain file contents
      refute result.key?(:state_content)

      # Must return memory_dir and config
      assert_equal ".ariadna_planning/memory", result[:memory_dir]
      assert result.key?(:config)

      # Must return verifier_model
      assert result.key?(:verifier_model)
    end
  end

  def test_verify_work_missing_phase_arg
    Dir.chdir(@dir) do
      assert_raises(SystemExit) do
        suppress_stderr { Ariadna::Tools::Init.dispatch(["verify-work"]) }
      end
    end
  end

  # --- new-project ---

  def test_new_project_returns_memory_dir_and_config
    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["new-project"]) }
      assert_equal ".ariadna_planning/memory", result[:memory_dir]
      assert result.key?(:config)
      assert result.key?(:researcher_model)
      assert result.key?(:is_brownfield)
    end
  end

  # --- new-milestone ---

  def test_new_milestone_returns_memory_dir_and_config
    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["new-milestone"]) }
      assert_equal ".ariadna_planning/memory", result[:memory_dir]
      assert result.key?(:config)
      assert_equal "v1.0", result[:current_milestone]
    end
  end

  # --- quick ---

  def test_quick_returns_memory_dir_and_config
    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(%w[quick fix login bug]) }
      assert_equal ".ariadna_planning/memory", result[:memory_dir]
      assert result.key?(:config)
      assert_equal 1, result[:next_num]
      assert_equal "fix-login-bug", result[:slug]
    end
  end

  # --- progress ---

  def test_progress_returns_memory_dir_and_config
    phase1_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase1_dir)
    File.write(File.join(phase1_dir, "01-01-PLAN.md"), "plan")
    File.write(File.join(phase1_dir, "01-01-SUMMARY.md"), "summary")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["progress"]) }
      assert_equal ".ariadna_planning/memory", result[:memory_dir]
      assert result.key?(:config)
      assert_equal 1, result[:phase_count]
      assert_equal 1, result[:completed_count]

      # Must NOT contain file contents
      refute result.key?(:state_content)
      refute result.key?(:roadmap_content)
    end
  end

  # --- map-codebase ---

  def test_map_codebase_returns_memory_dir_and_config
    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["map-codebase"]) }
      assert_equal ".ariadna_planning/memory", result[:memory_dir]
      assert result.key?(:config)
      assert result.key?(:mapper_model)
    end
  end

  # --- unknown workflow ---

  def test_unknown_workflow_errors
    Dir.chdir(@dir) do
      assert_raises(SystemExit) do
        suppress_stderr { Ariadna::Tools::Init.dispatch(["nonexistent"]) }
      end
    end
  end

  # --- no --include flag handling ---

  def test_no_include_flag_handling
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-PLAN.md"),
               "---\nphase: 1\nplan: 01\ndomain: backend\nwave: 1\n---\n")
    File.write(File.join(@planning_dir, "STATE.md"), "**Status:** Active\n")

    Dir.chdir(@dir) do
      # Even if we pass --include, it should be ignored (no state_content returned)
      result = capture_json { Ariadna::Tools::Init.dispatch(["execute-phase", "1", "--include", "state"]) }
      refute result.key?(:state_content)
    end
  end

  private

  def capture_json(&)
    output = capture_output(&)
    JSON.parse(output, symbolize_names: true)
  end

  def suppress_stderr
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
  ensure
    $stderr = old_stderr
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
    return result # rubocop:disable Lint/EnsureReturn
  end
end
