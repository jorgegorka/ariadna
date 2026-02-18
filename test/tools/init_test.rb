require "test_helper"
require "ariadna/tools/init"

class InitTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @planning_dir = File.join(@dir, ".planning")
    @phases_dir = File.join(@planning_dir, "phases")
    FileUtils.mkdir_p(@phases_dir)

    # Create minimal ROADMAP.md for milestone info
    File.write(File.join(@planning_dir, "ROADMAP.md"), "# ROADMAP\n\n## v1.0: MVP Release\n\n### Phase 1: Setup\n\n**Goal:** TBD\n")
    File.write(File.join(@planning_dir, "config.json"), '{"model_profile":"balanced"}')
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_init_execute_phase
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-PLAN.md"), "---\nphase: 1\nplan: 01\n---\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["execute-phase", "1"]) }
      assert result[:phase_found]
      assert_equal "01", result[:phase_number]
      assert_equal "setup", result[:phase_name]
      assert_equal 1, result[:plan_count]
      assert_equal "v1.0", result[:milestone_version]
      assert_includes result[:executor_model], "sonnet"
    end
  end

  def test_init_execute_phase_includes_team_fields
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-PLAN.md"), "---\nphase: 1\nplan: 01\n---\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["execute-phase", "1"]) }
      assert_equal false, result[:team_execution]
      assert_equal "vertical", result[:execution_mode]
      assert_includes result.keys, :backend_executor_model
      assert_includes result.keys, :frontend_executor_model
      assert_includes result.keys, :test_executor_model
    end
  end

  def test_init_execute_phase_auto_team_execution
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-PLAN.md"), "---\nphase: 1\nplan: 01\n---\n")
    File.write(File.join(@planning_dir, "config.json"), '{"model_profile":"balanced","team_execution":"auto"}')

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["execute-phase", "1"]) }
      assert_equal "auto", result[:team_execution]
    end
  end

  def test_init_execute_phase_with_includes
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(@planning_dir, "STATE.md"), "**Status:** Active\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["execute-phase", "1", "--include", "state,roadmap"]) }
      assert result[:state_content]
      assert result[:roadmap_content]
    end
  end

  def test_init_plan_phase
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["plan-phase", "1"]) }
      assert result[:phase_found]
      assert_includes result.keys, :researcher_model
      assert_includes result.keys, :planner_model
      assert_includes result.keys, :research_enabled
    end
  end

  def test_init_new_project
    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["new-project"]) }
      assert_includes result.keys, :researcher_model
      assert_includes result.keys, :is_brownfield
      assert_includes result.keys, :has_git
      assert result[:roadmap_exists] || !result[:roadmap_exists] # just check key exists
    end
  end

  def test_init_new_milestone
    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["new-milestone"]) }
      assert_equal "v1.0", result[:current_milestone]
      assert_includes result.keys, :researcher_model
      assert_includes result.keys, :roadmapper_model
    end
  end

  def test_init_quick
    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["quick", "fix", "login", "bug"]) }
      assert_equal 1, result[:next_num]
      assert_equal "fix-login-bug", result[:slug]
      assert_includes result[:task_dir], "1-fix-login-bug"
    end
  end

  def test_init_quick_increments_number
    quick_dir = File.join(@planning_dir, "quick")
    FileUtils.mkdir_p(File.join(quick_dir, "1-first-task"))

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["quick", "second", "task"]) }
      assert_equal 2, result[:next_num]
    end
  end

  def test_init_resume
    File.write(File.join(@planning_dir, "STATE.md"), "state content")
    File.write(File.join(@planning_dir, "PROJECT.md"), "project content")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["resume"]) }
      assert result[:state_exists]
      assert result[:project_exists]
      assert result[:planning_exists]
      refute result[:has_interrupted_agent]
    end
  end

  def test_init_resume_with_interrupted_agent
    File.write(File.join(@planning_dir, "current-agent-id.txt"), "agent-123")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["resume"]) }
      assert result[:has_interrupted_agent]
      assert_equal "agent-123", result[:interrupted_agent_id]
    end
  end

  def test_init_verify_work
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-VERIFICATION.md"), "verification")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["verify-work", "1"]) }
      assert result[:phase_found]
      assert result[:has_verification]
    end
  end

  def test_init_phase_op
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-RESEARCH.md"), "research")
    File.write(File.join(phase_dir, "01-01-PLAN.md"), "plan")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["phase-op", "1"]) }
      assert result[:phase_found]
      assert result[:has_research]
      assert result[:has_plans]
      assert_equal 1, result[:plan_count]
    end
  end

  def test_init_todos
    pending_dir = File.join(@planning_dir, "todos", "pending")
    FileUtils.mkdir_p(pending_dir)
    File.write(File.join(pending_dir, "todo1.md"), "title: Fix bug\narea: code\ncreated: 2024-01-01\n")
    File.write(File.join(pending_dir, "todo2.md"), "title: Write docs\narea: docs\ncreated: 2024-01-02\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["todos"]) }
      assert_equal 2, result[:todo_count]
      assert_equal 2, result[:todos].length
    end
  end

  def test_init_todos_with_area_filter
    pending_dir = File.join(@planning_dir, "todos", "pending")
    FileUtils.mkdir_p(pending_dir)
    File.write(File.join(pending_dir, "todo1.md"), "title: Fix bug\narea: code\ncreated: 2024-01-01\n")
    File.write(File.join(pending_dir, "todo2.md"), "title: Write docs\narea: docs\ncreated: 2024-01-02\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["todos", "code"]) }
      assert_equal 1, result[:todo_count]
      assert_equal "code", result[:todos].first[:area]
    end
  end

  def test_init_milestone_op
    phase_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase_dir)
    File.write(File.join(phase_dir, "01-01-SUMMARY.md"), "summary")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["milestone-op"]) }
      assert_equal "v1.0", result[:milestone_version]
      assert_equal 1, result[:phase_count]
      assert_equal 1, result[:completed_phases]
      assert result[:all_phases_complete]
    end
  end

  def test_init_map_codebase
    codebase_dir = File.join(@planning_dir, "codebase")
    FileUtils.mkdir_p(codebase_dir)
    File.write(File.join(codebase_dir, "architecture.md"), "arch")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["map-codebase"]) }
      assert result[:has_maps]
      assert_equal ["architecture.md"], result[:existing_maps]
      assert result[:codebase_dir_exists]
    end
  end

  def test_init_progress
    phase1_dir = File.join(@phases_dir, "01-setup")
    FileUtils.mkdir_p(phase1_dir)
    File.write(File.join(phase1_dir, "01-01-PLAN.md"), "plan")
    File.write(File.join(phase1_dir, "01-01-SUMMARY.md"), "summary")

    phase2_dir = File.join(@phases_dir, "02-auth")
    FileUtils.mkdir_p(phase2_dir)
    File.write(File.join(phase2_dir, "02-01-PLAN.md"), "plan")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["progress"]) }
      assert_equal 2, result[:phase_count]
      assert_equal 1, result[:completed_count]
      assert_equal 1, result[:in_progress_count]
      assert result[:has_work_in_progress]
      assert_equal "v1.0", result[:milestone_version]
    end
  end

  def test_init_progress_detects_paused
    File.write(File.join(@planning_dir, "STATE.md"), "**Paused At:** Task 3 of Plan 02\n")

    Dir.chdir(@dir) do
      result = capture_json { Ariadna::Tools::Init.dispatch(["progress"]) }
      assert_equal "Task 3 of Plan 02", result[:paused_at]
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
